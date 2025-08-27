require 'rails_helper'

RSpec.describe RestaurantImportService do
  let(:valid_json_data) do
    {
      'restaurants' => [
        {
          'name' => "Poppo's Cafe",
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 9.00 },
                { 'name' => 'Small Salad', 'price' => 5.00 }
              ]
            },
            {
              'name' => 'dinner',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 15.00 },
                { 'name' => 'Large Salad', 'price' => 8.00 }
              ]
            }
          ]
        }
      ]
    }
  end

  let(:json_with_dishes) do
    {
      'restaurants' => [
        {
          'name' => "Casa del Poppo",
          'menus' => [
            {
              'name' => 'lunch',
              'dishes' => [
                { 'name' => 'Chicken Wings', 'price' => 9.00 },
                { 'name' => 'Burger', 'price' => 9.00 }
              ]
            }
          ]
        }
      ]
    }
  end

  let(:json_with_duplicates) do
    {
      'restaurants' => [
        {
          'name' => "Test Restaurant",
          'menus' => [
            {
              'name' => 'lunch',
              'menu_items' => [
                { 'name' => 'Burger', 'price' => 9.00 },
                { 'name' => 'Burger', 'price' => 10.00 }, # Duplicate
                { 'name' => 'Salad', 'price' => 5.00 }
              ]
            }
          ]
        }
      ]
    }
  end

  describe '#import' do
    context 'with valid JSON data' do
      it 'creates restaurants, menus, and menu items' do
        service = RestaurantImportService.new(valid_json_data)
        result = service.import

        expect(result[:success]).to be true
        expect(result[:data][:restaurants_processed]).to eq(1)
        expect(result[:data][:menus_processed]).to eq(2)
        expect(result[:data][:items_processed]).to eq(4)

        restaurant = Restaurant.find_by(name: "Poppo's Cafe")
        expect(restaurant).to be_present
        expect(restaurant.menus.count).to eq(2)
        expect(restaurant.menu_items.distinct.count).to eq(3)

        item_names = restaurant.menu_items.distinct.pluck(:name).sort
        expect(item_names).to eq([ 'Burger', 'Large Salad', 'Small Salad' ].sort)
      end

      it 'handles both menu_items and dishes keys' do
        service = RestaurantImportService.new(json_with_dishes)
        result = service.import

        expect(result[:success]).to be true
        expect(result[:data][:restaurants_processed]).to eq(1)
        expect(result[:data][:menus_processed]).to eq(1)
        expect(result[:data][:items_processed]).to eq(2)
      end

      it 'consolidates duplicate items within the same menu' do
        service = RestaurantImportService.new(json_with_duplicates)
        result = service.import

        expect(result[:success]).to be true

        consolidation_log = result[:logs].find { |log| log[:message].include?('consolidated') }
        expect(consolidation_log).to be_present

        expect(result[:data][:items_processed]).to eq(2)
      end

      it 'is idempotent - re-importing updates existing records' do
        service = RestaurantImportService.new(valid_json_data)

        result1 = service.import
        expect(result1[:success]).to be true

        service2 = RestaurantImportService.new(valid_json_data)
        result2 = service2.import
        expect(result2[:success]).to be true

        expect(result2[:data][:restaurants_processed]).to eq(1)
        expect(result2[:data][:menus_processed]).to eq(2)
        expect(result2[:data][:items_processed]).to eq(4)
      end
    end

    context 'with invalid JSON data' do
      it 'returns error for invalid structure' do
        invalid_data = { 'invalid' => 'structure' }
        service = RestaurantImportService.new(invalid_data)

        result = service.import
        expect(result[:success]).to be false
        expect(result[:errors]).to include(/Invalid JSON structure/)
      end

      it 'returns error for missing restaurants key' do
        invalid_data = { 'restaurants' => 'not_an_array' }
        service = RestaurantImportService.new(invalid_data)

        result = service.import
        expect(result[:success]).to be false
        expect(result[:errors]).to include(/Invalid JSON structure/)
      end
    end

    context 'with validation errors' do
      it 'rolls back transaction on validation failure' do
        allow_any_instance_of(RestaurantImportService).to receive(:process_menu_item).and_raise(ActiveRecord::RecordInvalid.new(MenuMenuItem.new))

        service = RestaurantImportService.new(valid_json_data)
        result = service.import

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present

        expect(Restaurant.count).to eq(0)
      end
    end
  end

  describe 'logging' do
    it 'logs successful operations' do
      service = RestaurantImportService.new(valid_json_data)
      result = service.import

      expect(result[:logs]).to be_present

      restaurant_log = result[:logs].find { |log| log[:entity_type] == 'restaurant' }
      expect(restaurant_log).to be_present

      menu_log = result[:logs].find { |log| log[:entity_type] == 'menu' }
      expect(menu_log).to be_present

      item_log = result[:logs].find { |log| log[:entity_type] == 'menu_item' }
      expect(item_log).to be_present
    end

    it 'logs warnings for duplicate consolidation' do
      service = RestaurantImportService.new(json_with_duplicates)
      result = service.import

      warning_log = result[:logs].find { |log| log[:level] == 'warn' }
      expect(warning_log).to be_present
      expect(warning_log[:message]).to include('consolidated')
    end
  end
end
