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
                { 'name' => 'Burger', 'price' => 10.00 },
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

        expect(result[:data][:items_processed]).to eq(3)
        expect(result[:data][:restaurants_processed]).to eq(1)
        expect(result[:data][:menus_processed]).to eq(1)

        restaurant = Restaurant.find_by(name: "Test Restaurant")
        expect(restaurant).to be_present

        menu = restaurant.menus.find_by(name: "lunch")
        expect(menu).to be_present

        expect(menu.menu_items.count).to eq(2)

        burger_item = menu.menu_items.find_by(name: "Burger")
        expect(burger_item).to be_present

        menu_menu_item = MenuMenuItem.find_by(menu: menu, menu_item: burger_item)
        expect(menu_menu_item.price).to eq(10.00)
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
        allow_any_instance_of(RestaurantImportService).to receive(:process_relationships_batch).and_raise(ActiveRecord::RecordInvalid.new(MenuMenuItem.new))

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

      restaurant_log = result[:logs].find { |log| log[:message].include?('restaurants') }
      expect(restaurant_log).to be_present

      menu_log = result[:logs].find { |log| log[:message].include?('menus') }
      expect(menu_log).to be_present

      item_log = result[:logs].find { |log| log[:message].include?('menu items') }
      expect(item_log).to be_present
    end

    it 'logs warnings for duplicate consolidation' do
      service = RestaurantImportService.new(json_with_duplicates)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:logs]).to be_present

      consolidation_log = result[:logs].find { |log| log[:message].include?('Consolidated') }
      expect(consolidation_log).to be_present

      expect(result[:data][:items_processed]).to eq(3)
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(1)
    end

    it 'logs detailed information for each menu item' do
      service = RestaurantImportService.new(valid_json_data)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:item_logs]).to be_present
      expect(result[:item_logs].length).to eq(4)

      first_item_log = result[:item_logs].first
      expect(first_item_log[:restaurant_name]).to eq("Poppo's Cafe")
      expect(first_item_log[:menu_name]).to eq('lunch')
      expect(first_item_log[:item_name]).to eq('Burger')
      expect(first_item_log[:price]).to eq(9.00)
      expect(first_item_log[:status]).to eq('processed')
      expect(first_item_log[:message]).to eq('Item processed successfully')
      expect(first_item_log[:timestamp]).to be_present
    end
  end

  describe 'batch processing' do
    let(:large_json_data) do
      {
        'restaurants' => Array.new(1500) do |i|
          {
            'name' => "Restaurant #{i}",
            'menus' => [
              {
                'name' => "Menu #{i}",
                'menu_items' => [
                  { 'name' => "Item #{i}", 'price' => 10.00 + i }
                ]
              }
            ]
          }
        end
      }
    end

    it 'processes data in batches of 1000' do
      service = RestaurantImportService.new(large_json_data)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:data][:batches_processed]).to eq(2)
      expect(result[:data][:restaurants_processed]).to eq(1500)
      expect(result[:data][:menus_processed]).to eq(1500)
      expect(result[:data][:items_processed]).to eq(1500)
    end

    it 'logs batch processing information' do
      service = RestaurantImportService.new(large_json_data)
      result = service.import

      batch_logs = result[:logs].select { |log| log[:message].include?('Processing batch') }
      expect(batch_logs.length).to eq(2)

      completed_logs = result[:logs].select { |log| log[:message].include?('completed successfully') }
      expect(completed_logs.length).to eq(2)
    end
  end

  describe 'file handling' do
    let(:temp_file) { Tempfile.new([ 'test', '.json' ]) }
    let(:file_content) { valid_json_data.to_json }

    before do
      temp_file.write(file_content)
      temp_file.rewind
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'processes data from file path' do
      service = RestaurantImportService.new(temp_file.path)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(2)
      expect(result[:data][:items_processed]).to eq(4)
    end

    it 'validates file size' do
      large_content = "x" * (RestaurantImportService::MAX_FILE_SIZE + 1)
      temp_file.write(large_content)
      temp_file.rewind

      service = RestaurantImportService.new(temp_file.path)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include(/File size.*exceeds maximum allowed size/)
    end

    it 'raises error for non-existent file' do
      non_existent_path = "/tmp/this_file_definitely_does_not_exist_#{SecureRandom.uuid}.json"

      service = RestaurantImportService.new(non_existent_path)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include(/Invalid input/)
    end
  end

  describe 'error handling' do
    it 'handles empty restaurants array' do
      empty_data = { 'restaurants' => [] }
      service = RestaurantImportService.new(empty_data)

      result = service.import
      expect(result[:success]).to be false
      expect(result[:errors]).to include(/Restaurants array cannot be empty/)
    end

    it 'handles missing menus key' do
      data_without_menus = {
        'restaurants' => [
          { 'name' => 'Restaurant without menus' }
        ]
      }
      service = RestaurantImportService.new(data_without_menus)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include(/undefined method.*compact.*for nil/)
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(0)
      expect(result[:data][:items_processed]).to eq(0)
      expect(result[:item_logs]).to eq([])
    end

    it 'handles missing menu_items key' do
      data_without_items = {
        'restaurants' => [
          {
            'name' => 'Restaurant',
            'menus' => [
              { 'name' => 'Menu without items' }
            ]
          }
        ]
      }
      service = RestaurantImportService.new(data_without_items)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(1)
      expect(result[:data][:items_processed]).to eq(0)
      expect(result[:item_logs]).to eq([])
    end

    it 'handles nil and blank names gracefully' do
      data_with_nil_names = {
        'restaurants' => [
          {
            'name' => nil,
            'menus' => [
              {
                'name' => '',
                'menu_items' => [
                  { 'name' => '   ', 'price' => 10.00 }
                ]
              }
            ]
          },
          {
            'name' => 'Valid Restaurant',
            'menus' => [
              {
                'name' => 'Valid Menu',
                'menu_items' => [
                  { 'name' => 'Valid Item', 'price' => 15.00 }
                ]
              }
            ]
          }
        ]
      }
      service = RestaurantImportService.new(data_with_nil_names)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(1)
      expect(result[:data][:items_processed]).to eq(1)

      expect(Restaurant.count).to eq(1)
      expect(Restaurant.first.name).to eq('Valid Restaurant')
    end

    it 'handles critical errors and includes them in result' do
      allow_any_instance_of(RestaurantImportService).to receive(:validate_input).and_raise(StandardError, 'Test error')

      service = RestaurantImportService.new(valid_json_data)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include('Critical error: Test error')
      expect(result[:item_logs]).to eq([])
    end
  end

  describe 'data processing methods' do
    let(:service) { RestaurantImportService.new(valid_json_data) }

    it 'deduplicates items within the same menu' do
      items_data = [
        { 'name' => 'Item A', 'price' => 10.00 },
        { 'name' => 'Item A', 'price' => 15.00 },
        { 'name' => 'Item B', 'price' => 20.00 }
      ]

      deduped = service.send(:dedup_items_in_menu, items_data)
      expect(deduped.length).to eq(2)
      expect(deduped.map { |i| i['name'] }).to eq([ 'Item A', 'Item B' ])
      expect(deduped.find { |i| i['name'] == 'Item A' }['price']).to eq(15.00)
    end

    it 'handles safe_name method correctly' do
      expect(service.send(:safe_name, '  Test Name  ')).to eq('Test Name')
      expect(service.send(:safe_name, nil)).to be_nil
      expect(service.send(:safe_name, '')).to be_nil
      expect(service.send(:safe_name, '   ')).to be_nil
      expect(service.send(:safe_name, 'Valid')).to eq('Valid')
    end

    it 'formats file size correctly' do
      expect(service.send(:format_file_size, 1024)).to eq('1.0KB')
      expect(service.send(:format_file_size, 1024 * 1024)).to eq('1.0MB')
      expect(service.send(:format_file_size, 500)).to eq('500B')
    end
  end

  describe 'edge cases' do
    it 'handles restaurants with no menus' do
      data_no_menus = {
        'restaurants' => [
          { 'name' => 'Restaurant 1' },
          { 'name' => 'Restaurant 2' }
        ]
      }
      service = RestaurantImportService.new(data_no_menus)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include(/undefined method.*compact.*for nil/)
      expect(result[:data][:restaurants_processed]).to eq(2)
      expect(result[:data][:menus_processed]).to eq(0)
      expect(result[:data][:items_processed]).to eq(0)
      expect(result[:item_logs]).to eq([])
    end

    it 'handles menus with no items' do
      data_no_items = {
        'restaurants' => [
          {
            'name' => 'Restaurant',
            'menus' => [
              { 'name' => 'Menu 1' },
              { 'name' => 'Menu 2' }
            ]
          }
        ]
      }
      service = RestaurantImportService.new(data_no_items)
      result = service.import

      expect(result[:success]).to be true
      expect(result[:data][:restaurants_processed]).to eq(1)
      expect(result[:data][:menus_processed]).to eq(2)
      expect(result[:data][:items_processed]).to eq(0)
      expect(result[:item_logs]).to eq([])
    end

    it 'handles mixed valid and invalid data' do
      mixed_data = {
        'restaurants' => [
          { 'name' => 'Valid Restaurant 1' },
          { 'name' => nil },
          { 'name' => 'Valid Restaurant 2' },
          { 'name' => '' },
          { 'name' => 'Valid Restaurant 3' }
        ]
      }
      service = RestaurantImportService.new(mixed_data)
      result = service.import

      expect(result[:success]).to be false
      expect(result[:errors]).to include(/undefined method.*compact.*for nil/)
      expect(result[:data][:restaurants_processed]).to eq(3)
      expect(Restaurant.count).to eq(0)
      expect(result[:item_logs]).to eq([])
    end
  end
end
