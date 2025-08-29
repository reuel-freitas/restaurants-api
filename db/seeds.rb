# Seeds for testing the restaurant statistics system

puts "🌱 Starting seeds for restaurant statistics system testing..."

# Clear existing data
puts "🧹 Clearing existing data..."
Restaurant.destroy_all
MenuItem.destroy_all
Menu.destroy_all
MenuMenuItem.destroy_all

# Create global Menu Items
puts "🍽️ Creating menu items..."
menu_items = [
  { name: "Classic Burger", base_price: 15.50 },
  { name: "Veggie Burger", base_price: 18.00 },
  { name: "Gourmet Burger", base_price: 25.00 },
  { name: "French Fries", base_price: 8.50 },
  { name: "Cheese Fries", base_price: 12.00 },
  { name: "Onion Rings", base_price: 10.00 },
  { name: "Caesar Salad", base_price: 16.00 },
  { name: "Greek Salad", base_price: 18.50 },
  { name: "Soup of the Day", base_price: 14.00 },
  { name: "Onion Soup", base_price: 16.50 },
  { name: "Margherita Pizza", base_price: 22.00 },
  { name: "Pepperoni Pizza", base_price: 24.50 },
  { name: "Four Cheese Pizza", base_price: 26.00 },
  { name: "Veggie Pizza", base_price: 23.00 },
  { name: "Bolognese Lasagna", base_price: 28.00 },
  { name: "Veggie Lasagna", base_price: 26.50 },
  { name: "Carbonara Spaghetti", base_price: 24.00 },
  { name: "Pesto Spaghetti", base_price: 22.50 },
  { name: "Mushroom Risotto", base_price: 32.00 },
  { name: "Shrimp Risotto", base_price: 38.00 },
  { name: "Grilled Chicken Breast", base_price: 29.00 },
  { name: "Salmon Fillet", base_price: 42.00 },
  { name: "Beef Tenderloin", base_price: 55.00 },
  { name: "Picanha Steak", base_price: 48.00 },
  { name: "Chef's Dessert", base_price: 12.00 },
  { name: "Tiramisu", base_price: 15.00 },
  { name: "Cheesecake", base_price: 14.00 },
  { name: "Artisanal Ice Cream", base_price: 8.00 },
  { name: "Soft Drink", base_price: 6.00 },
  { name: "Natural Juice", base_price: 8.50 },
  { name: "Water", base_price: 4.00 },
  { name: "Craft Beer", base_price: 12.00 },
  { name: "House Wine", base_price: 18.00 },
  { name: "Chicken Wings", base_price: 16.00 },
  { name: "Fish & Chips", base_price: 20.00 },
  { name: "Tacos", base_price: 14.00 },
  { name: "Sushi Roll", base_price: 18.00 },
  { name: "Pad Thai", base_price: 19.00 },
  { name: "Curry", base_price: 21.00 },
  { name: "Steak Frites", base_price: 35.00 },
  { name: "Lobster Bisque", base_price: 28.00 },
  { name: "Bruschetta", base_price: 11.00 },
  { name: "Garlic Bread", base_price: 7.00 },
  { name: "Mozzarella Sticks", base_price: 13.00 }
]

created_items = menu_items.map do |item_data|
  MenuItem.create!(name: item_data[:name])
end

puts "✅ #{created_items.count} menu items created"

# Create 50 Restaurants with diverse types
puts "🏪 Creating 50 restaurants..."
restaurant_types = [
  "American", "Italian", "Japanese", "Mexican", "Indian", "Chinese", "Thai", "French", "Mediterranean", "Greek",
  "Brazilian", "Spanish", "Vietnamese", "Korean", "Lebanese", "Turkish", "Moroccan", "Ethiopian", "Caribbean", "Peruvian"
]

restaurants = []
50.times do |i|
  restaurant_type = restaurant_types[i % restaurant_types.length]
  restaurant_name = "#{restaurant_type} #{[ 'House', 'Palace', 'Garden', 'Corner', 'Spot', 'Kitchen', 'Bistro', 'Cafe', 'Grill', 'Diner' ][i % 10]} #{i + 1}"

  restaurants << Restaurant.create!(name: restaurant_name)
end

puts "✅ #{restaurants.count} restaurants created"

# Create Menus for each restaurant
puts "📋 Creating menus for each restaurant..."

menu_templates = [
  { name: "Main Menu", item_count: 8..12 },
  { name: "Lunch Special", item_count: 4..6 },
  { name: "Dinner Menu", item_count: 6..10 },
  { name: "Weekend Brunch", item_count: 5..8 },
  { name: "Happy Hour", item_count: 3..5 },
  { name: "Kids Menu", item_count: 3..4 },
  { name: "Vegetarian Options", item_count: 4..6 },
  { name: "Chef's Specials", item_count: 3..5 }
]

total_menus = 0
total_items = 0

restaurants.each do |restaurant|
  # Each restaurant gets 2-4 menus
  num_menus = rand(2..4)
  selected_templates = menu_templates.sample(num_menus)

  selected_templates.each do |template|
    menu = restaurant.menus.create!(name: template[:name])
    total_menus += 1

    # Select random items for this menu
    num_items = rand(template[:item_count])
    selected_items = menu_items.sample(num_items)

    selected_items.each do |item_data|
      item = MenuItem.find_by(name: item_data[:name])
      next unless item

      # Price variation per restaurant (simulate different pricing)
      price_variation = rand(0.7..1.5) # ±30% variation
      final_price = (item_data[:base_price] * price_variation).round(2)

      MenuMenuItem.create!(
        menu: menu,
        menu_item: item,
        price: final_price
      )
      total_items += 1
    end
  end
end

puts "✅ #{total_menus} menus created"
puts "✅ #{total_items} menu items created"

# Final statistics
puts "\n📊 Final seed statistics:"
puts "   Restaurants: #{Restaurant.count}"
puts "   Menus: #{Menu.count}"
puts "   Menu Items: #{MenuItem.count}"
puts "   Menu Menu Items: #{MenuMenuItem.count}"
puts "   Min Price: $#{MenuMenuItem.minimum(:price)}"
puts "   Max Price: $#{MenuMenuItem.maximum(:price)}"
puts "   Average Price: $#{MenuMenuItem.average(:price).round(2)}"

puts "\n🎉 Seed completed successfully!"
puts "💡 Now you can test the /up endpoint to see the statistics!"
