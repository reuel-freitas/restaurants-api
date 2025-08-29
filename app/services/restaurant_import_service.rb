require "set"

class RestaurantImportService
  attr_reader :logs, :errors, :stats

  MAX_FILE_SIZE = 5 * 1024 * 1024

  BATCH_SIZE = 1000

  def initialize(file_path_or_data)
    @file_path_or_data = file_path_or_data
    @logs = []
    @errors = []
    @item_logs = []  # Detailed logs for each menu item
    @stats = {
      restaurants_processed: 0,
      menus_processed: 0,
      items_processed: 0,
      batches_processed: 0
    }
  end

  def import
    validate_input
    process_import_in_batches
    { success: errors.empty?, logs: logs, errors: errors, data: stats, item_logs: @item_logs }
  rescue StandardError => e
    @errors << "Critical error: #{e.message}"
    { success: false, logs: logs, errors: errors, data: stats, item_logs: @item_logs }
  end

  private

  def validate_input
    if @file_path_or_data.is_a?(String) && File.exist?(@file_path_or_data)
      validate_file_size
      @json_data = JSON.parse(File.read(@file_path_or_data))
    elsif @file_path_or_data.is_a?(Hash)
      @json_data = @file_path_or_data
    else
      raise ArgumentError, "Invalid input: must be file path or JSON hash"
    end

    unless @json_data.is_a?(Hash) && @json_data["restaurants"].is_a?(Array)
      raise ArgumentError, "Invalid JSON structure: expected hash with restaurants array"
    end

    if @json_data["restaurants"].empty?
      raise ArgumentError, "Restaurants array cannot be empty"
    end
  end

  def validate_file_size
    file_size = File.size(@file_path_or_data)
    if file_size > MAX_FILE_SIZE
      raise ArgumentError, "File size (#{format_file_size(file_size)}) exceeds maximum allowed size of #{format_file_size(MAX_FILE_SIZE)}"
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

  def process_import_in_batches
    restaurants_data = @json_data["restaurants"]
    total_batches = (restaurants_data.length.to_f / BATCH_SIZE).ceil

    restaurants_data.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
      process_batch(batch, batch_index + 1, total_batches)
    end
  end

  def process_batch(batch, batch_number, total_batches)
    log_summary("Processing batch #{batch_number}/#{total_batches} (#{batch.length} restaurants)")

    ActiveRecord::Base.transaction do
      batch_restaurants = batch.map { |r| safe_name(r["name"]) }.compact
      process_restaurants_batch(batch_restaurants)

      batch_menus = batch.flat_map do |r|
        restaurant_name = safe_name(r["name"])
        next [] unless restaurant_name

        r["menus"]&.map do |m|
          menu_name = safe_name(m["name"])
          next nil unless menu_name
          [ restaurant_name, menu_name ]
        end.compact
      end.compact
      process_menus_batch(batch_menus)

      batch_items_with_prices = batch.flat_map do |r|
        restaurant_name = safe_name(r["name"])
        next [] unless restaurant_name

        r["menus"]&.flat_map do |m|
          menu_name = safe_name(m["name"])
          next [] unless menu_name

          items_data = m["menu_items"] || m["dishes"] || []

          deduped_items = dedup_items_in_menu(items_data)

          if items_data.length > deduped_items.length
            duplicates_count = items_data.length - deduped_items.length
            log_summary("Consolidated #{duplicates_count} duplicate items in menu '#{menu_name}' (last price wins)")
          end

          deduped_items.map do |item_data|
            item_name = safe_name(item_data["name"])
            next nil unless item_name

            log_menu_item(restaurant_name, menu_name, item_name, item_data["price"], "processed", "Item processed successfully")

            {
              restaurant_name: restaurant_name,
              menu_name: menu_name,
              item_name: item_name,
              price: item_data["price"]
            }
          end.compact
        end.compact
      end.compact

      process_menu_items_batch(batch_items_with_prices.map { |item| item[:item_name] })
      process_relationships_batch(batch_items_with_prices)

      total_items_in_batch = batch.flat_map do |r|
        r["menus"]&.flat_map do |m|
          (m["menu_items"] || m["dishes"] || []).map { |i| safe_name(i["name"]) }.compact
        end.compact
      end.compact.length

      @stats[:items_processed] += total_items_in_batch

      @stats[:batches_processed] += 1
    end

    log_summary("Batch #{batch_number}/#{total_batches} completed successfully")
  rescue StandardError => e
    @errors << "Batch #{batch_number} failed: #{e.message}"
    raise
  end

  def safe_name(name)
    return nil if name.nil?
    stripped = name.to_s.strip
    stripped.blank? ? nil : stripped
  end

  def dedup_items_in_menu(items_data)
    items_data.group_by { |item| safe_name(item["name"]) }
              .transform_values { |items| items.last }
              .values
              .compact
  end

  def process_restaurants_batch(restaurant_names)
    return if restaurant_names.empty?

    restaurants_to_insert = restaurant_names.map do |name|
      { name: name, created_at: Time.current, updated_at: Time.current }
    end

    Restaurant.insert_all(restaurants_to_insert, unique_by: :index_restaurants_on_name)
    @stats[:restaurants_processed] += restaurant_names.length

    log_summary("Inserted #{restaurant_names.length} restaurants")
  end

  def process_menus_batch(menu_data)
    return if menu_data.empty?

    restaurant_names = menu_data.map(&:first).uniq
    restaurant_ids = Restaurant.where(name: restaurant_names).pluck(:name, :id).to_h

    menus_to_insert = menu_data.map do |restaurant_name, menu_name|
      {
        restaurant_id: restaurant_ids[restaurant_name],
        name: menu_name,
        created_at: Time.current,
        updated_at: Time.current
      }
    end.compact

    return if menus_to_insert.empty?

    Menu.insert_all(menus_to_insert, unique_by: :index_menus_on_restaurant_id_and_name)
    @stats[:menus_processed] += menus_to_insert.length

    log_summary("Inserted #{menus_to_insert.length} menus")
  end

  def process_menu_items_batch(item_names)
    return if item_names.empty?

    items_to_insert = item_names.uniq.map do |name|
      { name: name, created_at: Time.current, updated_at: Time.current }
    end

    MenuItem.insert_all(items_to_insert, unique_by: :index_menu_items_on_name)

    log_summary("Inserted #{items_to_insert.length} unique menu items")
  end

  def process_relationships_batch(relationships)
    return if relationships.empty?

    restaurant_names = relationships.map { |r| r[:restaurant_name] }.uniq
    menu_names = relationships.map { |r| r[:menu_name] }.uniq
    item_names = relationships.map { |r| r[:item_name] }.uniq

    menu_ids = Menu.joins(:restaurant)
                   .where(restaurants: { name: restaurant_names }, menus: { name: menu_names })
                   .pluck("restaurants.name", "menus.name", "menus.id")
                   .group_by { |r_name, m_name, _| [ r_name, m_name ] }
                   .transform_values { |arr| arr.first.last }

    item_ids = MenuItem.where(name: item_names).pluck(:name, :id).to_h

    relationships_to_insert = relationships.map do |rel|
      menu_id = menu_ids[[ rel[:restaurant_name], rel[:menu_name] ]]
      item_id = item_ids[rel[:item_name]]

      next unless menu_id && item_id

      {
        menu_id: menu_id,
        menu_item_id: item_id,
        price: rel[:price],
        created_at: Time.current,
        updated_at: Time.current
      }
    end.compact

    return if relationships_to_insert.empty?

    MenuMenuItem.upsert_all(
      relationships_to_insert,
      unique_by: :index_menu_menu_items_on_menu_id_and_menu_item_id,
      record_timestamps: false
    )

    log_summary("Processed #{relationships_to_insert.length} menu-item relationships")
  end

  def log_summary(message)
    @logs << {
      level: "info",
      message: message,
      timestamp: Time.current,
      batch: @stats[:batches_processed]
    }

    if @stats[:batches_processed] % 10 == 0 || message.include?("completed")
      Rails.logger.info "[Import] #{message}"
    end
  end

  def log_menu_item(restaurant_name, menu_name, item_name, price, status, message = nil)
    @item_logs << {
      restaurant_name: restaurant_name,
      menu_name: menu_name,
      item_name: item_name,
      price: price,
      status: status,
      message: message,
      timestamp: Time.current
    }
  end
end
