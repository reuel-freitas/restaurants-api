class RestaurantsController < ApplicationController
  def index
    @restaurants = Restaurant.all
    render json: { restaurants: @restaurants }
  end

    def show
    @restaurant = Restaurant.includes(
      menus: [
        :menu_items,
        :menu_menu_items
      ]
    ).find(params[:id])

    serializer = RestaurantSerializerService.new(@restaurant)
    render json: serializer.serialize_with_menus
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Restaurant not found" }, status: :not_found
    end
end
