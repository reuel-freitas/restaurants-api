require 'rails_helper'

RSpec.describe 'Restaurants API', type: :request do
  describe 'GET /restaurants' do
    let!(:restaurant1) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:restaurant2) { create(:restaurant, name: "Casa del Poppo") }

    it 'returns all restaurants' do
      get '/restaurants'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('restaurants')
      expect(json_response['restaurants'].length).to eq(2)

      restaurant_names = json_response['restaurants'].map { |r| r['name'] }
      expect(restaurant_names).to include("Poppo's Cafe", "Casa del Poppo")
    end
  end

  describe 'GET /restaurants/:id' do
    let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:menu) { create(:menu, restaurant: restaurant, name: 'Lunch') }

    it 'returns the specific restaurant' do
      get "/restaurants/#{restaurant.id}"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('restaurant')
      expect(json_response['restaurant']['id']).to eq(restaurant.id)
      expect(json_response['restaurant']['name']).to eq("Poppo's Cafe")
    end

    it 'returns 404 for non-existent restaurant' do
      get '/restaurants/999'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /restaurants/:id/menus' do
    let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:menu1) { create(:menu, restaurant: restaurant, name: 'Lunch') }
    let!(:menu2) { create(:menu, restaurant: restaurant, name: 'Dinner') }

    it 'returns all menus for a specific restaurant' do
      get "/restaurants/#{restaurant.id}/menus"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menus')
      expect(json_response['menus'].length).to eq(2)

      menu_names = json_response['menus'].map { |m| m['name'] }
      expect(menu_names).to include('Lunch', 'Dinner')
    end
  end

  describe 'GET /restaurants/:id/menu_items' do
    let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:menu) { create(:menu, restaurant: restaurant, name: 'Lunch') }
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    before do
      MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)
    end

    it 'returns all menu items for a specific restaurant' do
      get "/restaurants/#{restaurant.id}/menu_items"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menu_items')
      expect(json_response['menu_items'].length).to eq(2)

      item_names = json_response['menu_items'].map { |i| i['name'] }
      expect(item_names).to include('Burger', 'Salad')
    end
  end
end
