require 'rails_helper'

RSpec.describe 'Menu Integration', type: :request do
  describe 'Menu with Menu Items' do
    let(:menu) { create(:menu, name: 'Lunch') }
    let!(:menu_item1) { create(:menu_item, name: 'Burger') }
    let!(:menu_item2) { create(:menu_item, name: 'Salad') }

    before do
      # Create the relationships with prices
      MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)
    end

    it 'shows menu with all its items and prices' do
      get "/menus/#{menu.id}"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['menu']['name']).to eq('Lunch')
      expect(json_response['menu']['menu_items']).to be_present
      expect(json_response['menu']['menu_items'].length).to eq(2)

      # Check that items have the correct structure
      burger_item = json_response['menu']['menu_items'].find { |item| item['name'] == 'Burger' }
      expect(burger_item).to be_present
      expect(burger_item['price'].to_f).to eq(9.00)

      salad_item = json_response['menu']['menu_items'].find { |item| item['name'] == 'Salad' }
      expect(salad_item).to be_present
      expect(salad_item['price'].to_f).to eq(5.00)
    end

    it 'allows the same menu item to appear in different menus with different prices' do
      dinner_menu = create(:menu, name: 'Dinner')
      MenuMenuItem.create!(menu: dinner_menu, menu_item: menu_item1, price: 15.00)

      get "/menus/#{dinner_menu.id}"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      burger_item = json_response['menu']['menu_items'].find { |item| item['name'] == 'Burger' }
      expect(burger_item['price'].to_f).to eq(15.00)
    end
  end

  describe 'Menu Items across multiple menus' do
    let!(:burger) { create(:menu_item, name: 'Burger') }
    let!(:lunch_menu) { create(:menu, name: 'Lunch') }
    let!(:dinner_menu) { create(:menu, name: 'Dinner') }

    before do
      MenuMenuItem.create!(menu: lunch_menu, menu_item: burger, price: 9.00)
      MenuMenuItem.create!(menu: dinner_menu, menu_item: burger, price: 15.00)
    end

    it 'shows menu item with all its associated menus' do
      get "/menu_items/#{burger.id}"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['menu_item']['name']).to eq('Burger')
      expect(json_response['menu_item']['menus']).to be_present
      expect(json_response['menu_item']['menus'].length).to eq(2)

      menu_names = json_response['menu_item']['menus'].map { |m| m['name'] }
      expect(menu_names).to include('Lunch', 'Dinner')
    end
  end
end
