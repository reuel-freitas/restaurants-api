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
    @menu = Menu.find(params[:id])
    render json: {
      menu: @menu.as_json(include: {
        restaurant: {},
        menu_items: {}
      }).merge(
        menu_items: @menu.menu_items.map do |item|
          {
            id: item.id,
            name: item.name,
            price: @menu.menu_menu_items.find_by(menu_item: item)&.price
          }
        end
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Menu not found" }, status: :not_found
  end
end
