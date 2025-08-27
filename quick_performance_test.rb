#!/usr/bin/env ruby

require_relative 'config/environment'
require 'benchmark'
require 'json'

# Quick performance test for different JSON sizes
puts "🚀 Quick Performance Test - RestaurantImportService"
puts "=" * 60

# Test sizes
test_sizes = [
  { name: "100KB", size: 100 * 1024 },
  { name: "500KB", size: 500 * 1024 },
  { name: "1MB", size: 1 * 1024 * 1024 },
  { name: "2MB", size: 2 * 1024 * 1024 },
  { name: "3MB", size: 3 * 1024 * 1024 },
  { name: "4MB", size: 4 * 1024 * 1024 }
]

# Helper methods
def generate_simple_test_data(target_size)
  restaurants = []
  current_size = 0
  restaurant_id = 1

  while current_size < target_size
    restaurant = {
      "name" => "Test Restaurant #{restaurant_id}",
      "menus" => [
        {
          "name" => "Main Menu",
          "menu_items" => generate_menu_items(restaurant_id)
        }
      ]
    }

    restaurant_json = restaurant.to_json
    if current_size + restaurant_json.bytesize > target_size
      break
    end

    restaurants << restaurant
    current_size += restaurant_json.bytesize
    restaurant_id += 1
  end

  { "restaurants" => restaurants }
end

def generate_menu_items(restaurant_id)
  num_items = rand(5..10)
  items = []

  num_items.times do |i|
    items << {
      "name" => "Item #{i + 1} from Restaurant #{restaurant_id}",
      "price" => rand(20.0..80.0).round(2),
      "description" => "Description of item #{i + 1} with details about ingredients and preparation"
    }
  end

  items
end

def format_size(bytes)
  if bytes >= 1024 * 1024
    "#{(bytes / (1024.0 * 1024.0)).round(2)}MB"
  elsif bytes >= 1024
    "#{(bytes / 1024.0).round(2)}KB"
  else
    "#{bytes}B"
  end
end

# Run tests
test_sizes.each do |config|
  puts "\n📊 Testing: #{config[:name]}"
  puts "-" * 30

  # Generate test data
  json_data = generate_simple_test_data(config[:size])
  actual_size = json_data.to_json.bytesize

  puts "📏 Actual size: #{format_size(actual_size)}"

  # Time test
  time_result = Benchmark.measure do
    service = RestaurantImportService.new(json_data)
    result = service.import

    if result[:success]
      puts "✅ Success: #{result[:data][:restaurants_processed]} restaurants, #{result[:data][:items_processed]} items"
    else
      puts "❌ Failed: #{result[:errors].join(', ')}"
    end
  end

  puts "⏱️  Time: #{time_result.real.round(3)}s"
end

puts "\n" + "=" * 60
puts "�� Test completed!"
