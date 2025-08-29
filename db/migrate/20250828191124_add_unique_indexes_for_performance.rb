class AddUniqueIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    add_index :restaurants, :name, unique: true, name: 'index_restaurants_on_name'
    add_index :menus, [ :restaurant_id, :name ], unique: true, name: 'index_menus_on_restaurant_id_and_name'
    add_index :menu_menu_items, [ :menu_id, :menu_item_id ], unique: true, name: 'index_menu_menu_items_on_menu_id_and_menu_item_id'
  end
end
