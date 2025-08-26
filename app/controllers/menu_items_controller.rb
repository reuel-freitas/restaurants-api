class MenuItemsController < ApplicationController
  def index
    if params[:restaurant_id]
      @restaurant = Restaurant.find(params[:restaurant_id])
      if params[:menu_id]
        @menu = @restaurant.menus.find(params[:menu_id])
        @menu_items = @menu.menu_items
      else
        @menu_items = @restaurant.menu_items.distinct
      end
    else
      @menu_items = MenuItem.all
    end
    render json: { menu_items: @menu_items }
  end

  def show
    @menu_item = MenuItem.find(params[:id])
    render json: {
      menu_item: @menu_item.as_json(include: {
        menus: {}
      })
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Menu item not found" }, status: :not_found
  end
end
