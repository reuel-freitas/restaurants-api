require 'rails_helper'

RSpec.describe MenuItemsController, type: :controller do
  describe 'GET #index' do
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    it 'returns all menu items' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('menu_items')
      expect(JSON.parse(response.body)['menu_items'].length).to eq(2)
    end

    it 'returns menu items with correct structure' do
      get :index

      json_response = JSON.parse(response.body)
      expect(json_response['menu_items'].first).to have_key('id')
      expect(json_response['menu_items'].first).to have_key('name')
      expect(json_response['menu_items'].first).to have_key('created_at')
      expect(json_response['menu_items'].first).to have_key('updated_at')
    end
  end

  describe 'GET #show' do
    let(:menu_item) { create(:menu_item, name: 'Burger') }

    it 'returns the specific menu item' do
      get :show, params: { id: menu_item.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['menu_item']['id']).to eq(menu_item.id)
      expect(json_response['menu_item']['name']).to eq('Burger')
    end

    it 'returns 404 for non-existent menu item' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end
end
