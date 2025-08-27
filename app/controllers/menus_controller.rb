class MenusController < ApplicationController
  def index
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      @menus = @restaurant.menus
    else
      @menus = Menu.all
    end
    render json: { menus: @menus }
  end

  def show
    @menu = Menu.includes(
      :restaurant,
      :menu_items,
      :menu_menu_items
    ).find(params[:id])

    render json: {
      menu: @menu.as_json(include: {
        restaurant: {}
      }).merge(
        menu_items: @menu.menu_items.map do |item|
          menu_menu_item = @menu.menu_menu_items.find { |mmi| mmi.menu_item_id == item.id }
          {
            id: item.id,
            name: item.name,
            price: menu_menu_item&.price&.to_f&.round(2)
          }
        end
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Menu not found" }, status: :not_found
  end
end
