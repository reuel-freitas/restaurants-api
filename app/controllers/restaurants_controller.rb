class RestaurantsController < ApplicationController
  def index
    @restaurants = Restaurant.page(params[:page]).per(10)
    render json: {
      restaurants: @restaurants,
      pagination: {
        current_page: @restaurants.current_page,
        total_pages: @restaurants.total_pages,
        total_count: @restaurants.total_count,
        per_page: @restaurants.limit_value
      }
    }
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
