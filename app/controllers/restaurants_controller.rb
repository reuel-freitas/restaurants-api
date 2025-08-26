class RestaurantsController < ApplicationController
  def index
    @restaurants = Restaurant.all
    render json: { restaurants: @restaurants }
  end

  def show
    @restaurant = Restaurant.find(params[:id])
    render json: {
      restaurant: @restaurant.as_json(include: {
        menus: {
          include: {
            menu_items: {}
          }
        }
      }).merge(
        menus: @restaurant.menus.map do |menu|
          {
            id: menu.id,
            name: menu.name,
            menu_items: menu.menu_items.map do |item|
              {
                id: item.id,
                name: item.name,
                price: menu.menu_menu_items.find_by(menu_item: item)&.price
              }
            end
          }
        end
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Restaurant not found" }, status: :not_found
  end
end
