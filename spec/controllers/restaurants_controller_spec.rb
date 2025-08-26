require 'rails_helper'

RSpec.describe RestaurantsController, type: :controller do
  describe 'GET #index' do
    let!(:restaurant1) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:restaurant2) { create(:restaurant, name: "Casa del Poppo") }

    it 'returns all restaurants' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('restaurants')
      expect(JSON.parse(response.body)['restaurants'].length).to eq(2)
    end

    it 'returns restaurants with correct structure' do
      get :index

      json_response = JSON.parse(response.body)
      expect(json_response['restaurants'].first).to have_key('id')
      expect(json_response['restaurants'].first).to have_key('name')
      expect(json_response['restaurants'].first).to have_key('created_at')
      expect(json_response['restaurants'].first).to have_key('updated_at')
    end
  end

  describe 'GET #show' do
    let(:restaurant) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:menu1) { create(:menu, restaurant: restaurant, name: 'Lunch') }
    let!(:menu2) { create(:menu, restaurant: restaurant, name: 'Dinner') }
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    before do
      MenuMenuItem.create!(menu: menu1, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu1, menu_item: menu_item2, price: 5.00)
      MenuMenuItem.create!(menu: menu2, menu_item: menu_item1, price: 15.00)
    end

    it 'returns the specific restaurant with menus and items' do
      get :show, params: { id: restaurant.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['restaurant']['id']).to eq(restaurant.id)
      expect(json_response['restaurant']['name']).to eq("Poppo's Cafe")
    end

    it 'returns restaurant with its menus' do
      get :show, params: { id: restaurant.id }

      json_response = JSON.parse(response.body)
      expect(json_response['restaurant']).to have_key('menus')
      expect(json_response['restaurant']['menus'].length).to eq(2)
    end

    it 'returns 404 for non-existent restaurant' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end
end
