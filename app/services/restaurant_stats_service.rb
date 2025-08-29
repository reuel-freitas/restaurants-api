class RestaurantStatsService
  DEFAULT_PER_PAGE = 25
  CACHE_TTL = 5.minutes

  def self.generate_stats(options = {})
    new(options).generate_stats
  end

  def initialize(options = {})
    @page = options[:page] || 1
    @per_page = options[:per_page] || DEFAULT_PER_PAGE
    @restaurant_ids = options[:restaurant_ids]
    @with_items = options[:with_items] || false
    @cache_key = generate_cache_key
  end

  def generate_stats
    Rails.cache.fetch(@cache_key, expires_in: CACHE_TTL) do
      {
        summary: generate_summary_stats,
        restaurants: generate_restaurant_details,
        pricing_analysis: generate_pricing_analysis,
        pagination: generate_pagination_info
      }
    end
  end

  def generate_restaurant_summary
    query = Restaurant.all
    query = query.where(id: @restaurant_ids) if @restaurant_ids.present?

    total_restaurants = query.count

    sample_restaurants = query.includes(menus: [ :menu_items, :menu_menu_items ])
                              .limit(5)
                              .map do |restaurant|
      {
        id: restaurant.id,
        name: restaurant.name,
        menu_count: restaurant.menus.count,
        total_items: restaurant.menu_items.count
      }
    end

    {
      total_count: total_restaurants,
      sample_restaurants: sample_restaurants,
      message: total_restaurants > 5 ? "Showing 5 of #{total_restaurants} restaurants" : "All restaurants shown"
    }
  end

  private

  def generate_cache_key
    "restaurant_stats:#{@page}:#{@per_page}:#{@restaurant_ids&.sort&.join('-')}:#{@with_items}:#{Restaurant.maximum(:updated_at)&.to_i}"
  end

  def generate_summary_stats
    {
      total_restaurants: Restaurant.count,
      total_menus: Menu.count,
      total_menu_items: MenuItem.count,
      total_menu_item_instances: MenuMenuItem.count,
      average_menus_per_restaurant: calculate_average_menus_per_restaurant,
      average_items_per_menu: calculate_average_items_per_menu
    }
  end

  def generate_restaurant_details
    query = Restaurant.includes(menus: [ :menu_items, :menu_menu_items ])

    query = query.where(id: @restaurant_ids) if @restaurant_ids.present?

    offset = (@page - 1) * @per_page
    restaurants = query.limit(@per_page).offset(offset).to_a

    restaurants.map do |restaurant|
      restaurant_data = {
        id: restaurant.id,
        name: restaurant.name,
        menu_count: restaurant.menus.count,
        total_items: restaurant.menu_items.count
      }

      if @with_items
        restaurant_data[:menus] = build_menus_data(restaurant)
      end

      restaurant_data
    end
  end

  def build_menus_data(restaurant)
    menu_items_map = restaurant.menu_menu_items.index_by(&:menu_item_id)

    restaurant.menus.map do |menu|
      {
        id: menu.id,
        name: menu.name,
        item_count: menu.menu_items.count,
        items: menu.menu_items.map do |item|
          menu_menu_item = menu_items_map[item.id]
          {
            id: item.id,
            name: item.name,
            price: menu_menu_item&.price&.to_d
          }
        end
      }
    end
  end

  def generate_pricing_analysis
    {
      price_ranges: calculate_overall_price_ranges,
      price_distribution: calculate_price_distribution
    }
  end

  def generate_pagination_info
    query = Restaurant.all
    query = query.where(id: @restaurant_ids) if @restaurant_ids.present?

    total_count = query.count
    total_pages = (total_count.to_f / @per_page).ceil

    {
      current_page: @page,
      per_page: @per_page,
      total_pages: total_pages,
      total_count: total_count,
      first_page: @page == 1,
      last_page: @page == total_pages,
      next_page: @page < total_pages ? @page + 1 : nil,
      prev_page: @page > 1 ? @page - 1 : nil
    }
  end

  def calculate_average_menus_per_restaurant
    return 0 if Restaurant.count.zero?
    (Menu.count.to_f / Restaurant.count).round(2)
  end

  def calculate_average_items_per_menu
    return 0 if Menu.count.zero?
    (MenuMenuItem.count.to_f / Menu.count).round(2)
  end

  def calculate_overall_price_ranges
    result = MenuMenuItem.connection.select_one(
      "SELECT MIN(price) as min_price, MAX(price) as max_price, AVG(price) as avg_price FROM menu_menu_items"
    )

    return { min: 0, max: 0, average: 0 } unless result

    {
      min: result["min_price"].to_d,
      max: result["max_price"].to_d,
      average: result["avg_price"].to_d.round(2)
    }
  end

  def calculate_price_distribution
    prices = MenuMenuItem.pluck(:price)
    return {} if prices.empty?

    ranges = {
      "0-5" => 0,
      "5-10" => 0,
      "10-15" => 0,
      "15-20" => 0,
      "20-30" => 0,
      "30+" => 0
    }

    prices.each do |price|
      price_float = price.to_f
      case price_float
      when 0..5
        ranges["0-5"] += 1
      when 5..10
        ranges["5-10"] += 1
      when 10..15
        ranges["10-15"] += 1
      when 15..20
        ranges["15-20"] += 1
      when 20..30
        ranges["20-30"] += 1
      else
        ranges["30+"] += 1
      end
    end

    ranges
  end

  def top_expensive_items(limit = 10)
    MenuMenuItem.joins(:menu_item)
                .select("menu_items.name, menu_menu_items.price")
                .order("menu_menu_items.price DESC")
                .limit(limit)
                .map { |mmi| { name: mmi.menu_item.name, price: mmi.price.to_d } }
  end

  def top_cheap_items(limit = 10)
    MenuMenuItem.joins(:menu_item)
                .select("menu_items.name, menu_menu_items.price")
                .order("menu_menu_items.price ASC")
                .limit(limit)
                .map { |mmi| { name: mmi.menu_item.name, price: mmi.price.to_d } }
  end

  def restaurant_specific_stats(restaurant_id)
    restaurant = Restaurant.find(restaurant_id)

    {
      id: restaurant.id,
      name: restaurant.name,
      menu_count: restaurant.menus.count,
      total_items: restaurant.menu_items.count,
      average_price: restaurant.menu_menu_items.average(:price)&.to_d&.round(2) || 0,
      price_range: {
        min: restaurant.menu_menu_items.minimum(:price)&.to_d || 0,
        max: restaurant.menu_menu_items.maximum(:price)&.to_d || 0
      }
    }
  end
end
