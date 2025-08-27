class RestaurantSerializerService
  def initialize(restaurant)
    @restaurant = restaurant
  end

  def serialize_with_menus
    {
      restaurant: @restaurant.as_json(except: [ :created_at, :updated_at ]).merge(
        menus: build_menus_data
      )
    }
  end

  private

  def build_menus_data
    @restaurant.menus.map do |menu|
      {
        id: menu.id,
        name: menu.name,
        menu_items: build_menu_items_data(menu)
      }
    end
  end

  def build_menu_items_data(menu)
    menu.menu_items.map do |item|
      menu_menu_item = menu.menu_menu_items.find { |mmi| mmi.menu_item_id == item.id }
      {
        id: item.id,
        name: item.name,
        price: menu_menu_item&.price&.to_f&.round(2)
      }
    end
  end
end
