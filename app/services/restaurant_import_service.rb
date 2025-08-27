class RestaurantImportService
  attr_reader :logs, :errors, :stats

  # Maximum allowed JSON size in bytes (5MB)
  MAX_JSON_SIZE = 5 * 1024 * 1024

  def initialize(json_data)
    @json_data = json_data
    @logs = []
    @errors = []
    @stats = {
      restaurants_processed: 0,
      menus_processed: 0,
      items_processed: 0
    }
  end

  def import
    validate_json_structure
    process_import
    { success: errors.empty?, logs: logs, errors: errors, data: stats }
  rescue StandardError => e
    @errors << "Critical error: #{e.message}"
    { success: false, logs: logs, errors: errors, data: stats }
  end

  private

  def validate_json_structure
    validate_json_size
    unless @json_data.is_a?(Hash) && @json_data["restaurants"].is_a?(Array)
      raise ArgumentError, "Invalid JSON structure: expected hash with restaurants array"
    end

    if @json_data["restaurants"].empty?
      raise ArgumentError, "Restaurants array cannot be empty"
    end
  end

  def validate_json_size
    json_size = @json_data.to_json.bytesize
    if json_size > MAX_JSON_SIZE
      raise ArgumentError, "JSON data size (#{format_file_size(json_size)}) exceeds maximum allowed size of #{format_file_size(MAX_JSON_SIZE)}"
    end
  end

  def format_file_size(bytes)
    if bytes >= 1024 * 1024
      "#{(bytes / (1024.0 * 1024.0)).round(2)}MB"
    elsif bytes >= 1024
      "#{(bytes / 1024.0).round(2)}KB"
    else
      "#{bytes}B"
    end
  end

  def process_import
    ActiveRecord::Base.transaction do
      @json_data["restaurants"].each do |restaurant_data|
        process_restaurant(restaurant_data)
      end
    end
  end

  def process_restaurant(restaurant_data)
    restaurant = find_or_create_restaurant(restaurant_data["name"])
    @stats[:restaurants_processed] += 1

    restaurant_data["menus"].each do |menu_data|
      process_menu(restaurant, menu_data)
    end
  end

  def process_menu(restaurant, menu_data)
    menu = find_or_create_menu(restaurant, menu_data["name"])
    @stats[:menus_processed] += 1

    # Handle both 'menu_items' and 'dishes' keys
    items_data = menu_data["menu_items"] || menu_data["dishes"] || []

    # Consolidate duplicate items within the same menu
    consolidated_items = consolidate_items(items_data)

    consolidated_items.each do |item_data|
      process_menu_item(menu, item_data)
    end
  end

  def process_menu_item(menu, item_data)
    menu_item = find_or_create_menu_item(item_data["name"])
    @stats[:items_processed] += 1

    # Create or update the relationship with price
    menu_menu_item = MenuMenuItem.find_or_initialize_by(
      menu: menu,
      menu_item: menu_item
    )

    menu_menu_item.price = item_data["price"]

    if menu_menu_item.save
      @logs << {
        level: "info",
        message: "Menu item '#{item_data['name']}' processed successfully in menu '#{menu.name}'",
        entity_type: "menu_item",
        entity_name: item_data["name"]
      }
    else
      @errors << "Failed to save menu item '#{item_data['name']}': #{menu_menu_item.errors.full_messages.join(', ')}"
      raise ActiveRecord::RecordInvalid, menu_menu_item
    end
  end

  def find_or_create_restaurant(name)
    Restaurant.find_or_create_by(name: name) do |restaurant|
      @logs << {
        level: "info",
        message: "Restaurant '#{name}' created successfully",
        entity_type: "restaurant",
        entity_name: name
      }
    end
  end

  def find_or_create_menu(restaurant, name)
    restaurant.menus.find_or_create_by(name: name) do |menu|
      @logs << {
        level: "info",
        message: "Menu '#{name}' created successfully for restaurant '#{restaurant.name}'",
        entity_type: "menu",
        entity_name: name
      }
    end
  end

  def find_or_create_menu_item(name)
    MenuItem.find_or_create_by(name: name) do |menu_item|
      @logs << {
        level: "info",
        message: "Menu item '#{name}' created successfully",
        entity_type: "menu_item",
        entity_name: name
      }
    end
  end

  def consolidate_items(items_data)
    # Group items by name and consolidate duplicates
    grouped_items = items_data.group_by { |item| item["name"] }

    consolidated = []
    grouped_items.each do |name, items|
      if items.length > 1
        # Take the first item and log the consolidation
        consolidated << items.first
        @logs << {
          level: "warn",
          message: "Duplicate item '#{name}' consolidated in menu (kept first occurrence)",
          entity_type: "menu_item",
          entity_name: name
        }
      else
        consolidated << items.first
      end
    end

    consolidated
  end
end
