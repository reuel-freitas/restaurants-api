require 'rails_helper'

RSpec.describe MenusController, type: :controller do
  describe 'GET #index' do
    let!(:menu1) { create(:menu, name: 'Lunch') }
    let!(:menu2) { create(:menu, name: 'Dinner') }

    it 'returns all menus' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('menus')
      expect(JSON.parse(response.body)['menus'].length).to eq(2)
    end

    it 'returns menus with correct structure' do
      get :index

      json_response = JSON.parse(response.body)
      expect(json_response['menus'].first).to have_key('id')
      expect(json_response['menus'].first).to have_key('name')
      expect(json_response['menus'].first).to have_key('created_at')
      expect(json_response['menus'].first).to have_key('updated_at')
    end
  end

  describe 'GET #show' do
    let(:menu) { create(:menu, name: 'Lunch') }
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    before do
      # Associate menu items with menu through the join table
      MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)
    end

    it 'returns the specific menu' do
      get :show, params: { id: menu.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['menu']['id']).to eq(menu.id)
      expect(json_response['menu']['name']).to eq('Lunch')
    end

    it 'returns menu with its items' do
      get :show, params: { id: menu.id }

      json_response = JSON.parse(response.body)
      expect(json_response['menu']).to have_key('menu_items')
      expect(json_response['menu']['menu_items'].length).to eq(2)
    end

    it 'returns 404 for non-existent menu' do
      get :show, params: { id: 999 }

      expect(response).to have_http_status(:not_found)
    end
  end
end
