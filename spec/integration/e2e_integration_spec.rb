require 'rails_helper'

RSpec.describe 'E2E Integration', type: :request do
  describe 'Complete Restaurant-Menu-MenuItem Hierarchy' do
    let!(:poppos_cafe) { create(:restaurant, name: "Poppo's Cafe") }
    let!(:casa_del_poppo) { create(:restaurant, name: "Casa del Poppo") }

    let!(:poppos_lunch) { create(:menu, restaurant: poppos_cafe, name: 'lunch') }
    let!(:poppos_dinner) { create(:menu, restaurant: poppos_cafe, name: 'dinner') }
    let!(:casa_lunch) { create(:menu, restaurant: casa_del_poppo, name: 'lunch') }
    let!(:casa_dinner) { create(:menu, restaurant: casa_del_poppo, name: 'dinner') }

    let!(:burger) { create(:menu_item, name: 'Burger') }
    let!(:salad) { create(:menu_item, name: 'Small Salad') }
    let!(:large_salad) { create(:menu_item, name: 'Large Salad') }
    let!(:chicken_wings) { create(:menu_item, name: 'Chicken Wings') }
    let!(:mega_burger) { create(:menu_item, name: 'Mega "Burger"') }
    let!(:lobster_mac) { create(:menu_item, name: 'Lobster Mac & Cheese') }

    before do
      MenuMenuItem.create!(menu: poppos_lunch, menu_item: burger, price: 9.00)
      MenuMenuItem.create!(menu: poppos_lunch, menu_item: salad, price: 5.00)

      MenuMenuItem.create!(menu: poppos_dinner, menu_item: burger, price: 15.00)
      MenuMenuItem.create!(menu: poppos_dinner, menu_item: large_salad, price: 8.00)

      MenuMenuItem.create!(menu: casa_lunch, menu_item: chicken_wings, price: 9.00)
      MenuMenuItem.create!(menu: casa_lunch, menu_item: burger, price: 9.00)

      MenuMenuItem.create!(menu: casa_dinner, menu_item: mega_burger, price: 22.00)
      MenuMenuItem.create!(menu: casa_dinner, menu_item: lobster_mac, price: 31.00)
    end

    it 'demonstrates complete restaurant hierarchy' do
      get '/restaurants'
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['restaurants'].length).to eq(2)

      restaurant_names = json_response['restaurants'].map { |r| r['name'] }
      expect(restaurant_names).to include("Poppo's Cafe", "Casa del Poppo")
    end

    it 'shows restaurant with all its menus and items' do
      get "/restaurants/#{poppos_cafe.id}"
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      restaurant = json_response['restaurant']

      expect(restaurant['name']).to eq("Poppo's Cafe")
      expect(restaurant['menus'].length).to eq(2)

      lunch_menu = restaurant['menus'].find { |m| m['name'] == 'lunch' }
      expect(lunch_menu['menu_items'].length).to eq(2)
      expect(lunch_menu['menu_items'].map { |i| i['name'] }).to include('Burger', 'Small Salad')

      dinner_menu = restaurant['menus'].find { |m| m['name'] == 'dinner' }
      expect(dinner_menu['menu_items'].length).to eq(2)
      expect(dinner_menu['menu_items'].map { |i| i['name'] }).to include('Burger', 'Large Salad')
    end

    it 'demonstrates nested API endpoints' do
      get "/restaurants/#{poppos_cafe.id}/menus"
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['menus'].length).to eq(2)

      get "/restaurants/#{poppos_cafe.id}/menu_items"
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['menu_items'].length).to eq(3)

      get "/restaurants/#{poppos_cafe.id}/menus/#{poppos_lunch.id}/menu_items"
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['menu_items'].length).to eq(2)
    end

    it 'demonstrates price variations for same item across menus' do
      get "/restaurants/#{poppos_cafe.id}"
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      restaurant = json_response['restaurant']

      lunch_menu = restaurant['menus'].find { |m| m['name'] == 'lunch' }
      dinner_menu = restaurant['menus'].find { |m| m['name'] == 'dinner' }

      lunch_burger = lunch_menu['menu_items'].find { |i| i['name'] == 'Burger' }
      dinner_burger = dinner_menu['menu_items'].find { |i| i['name'] == 'Burger' }

      expect(lunch_burger['price'].to_f).to eq(9.00)
      expect(dinner_burger['price'].to_f).to eq(15.00)
    end

    it 'demonstrates unique menu item names across restaurants' do
      get "/restaurants/#{poppos_cafe.id}/menu_items"
      poppos_items = JSON.parse(response.body)['menu_items'].map { |i| i['name'] }

      get "/restaurants/#{casa_del_poppo.id}/menu_items"
      casa_items = JSON.parse(response.body)['menu_items'].map { |i| i['name'] }

      expect(poppos_items).to include('Burger')
      expect(casa_items).to include('Burger')

      poppos_burger = poppos_items.find { |i| i == 'Burger' }
      casa_burger = casa_items.find { |i| i == 'Burger' }

      expect(poppos_burger).to eq(casa_burger)
    end
  end
end
