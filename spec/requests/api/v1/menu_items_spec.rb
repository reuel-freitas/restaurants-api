require 'rails_helper'

RSpec.describe 'Menu Items API', type: :request do
    describe 'GET /menu_items' do
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    it 'returns all menu items' do
      get '/menu_items'
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menu_items')
      expect(json_response['menu_items'].length).to eq(2)

      item_names = json_response['menu_items'].map { |i| i['name'] }
      expect(item_names).to include('Burger', 'Salad')
    end
  end

  describe 'GET /menu_items/:id' do
    let(:menu_item) { create(:menu_item, name: 'Burger') }

    it 'returns the specific menu item' do
      get "/menu_items/#{menu_item.id}"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('menu_item')
      expect(json_response['menu_item']['id']).to eq(menu_item.id)
      expect(json_response['menu_item']['name']).to eq('Burger')
    end

    it 'returns 404 for non-existent menu item' do
      get '/menu_items/999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
