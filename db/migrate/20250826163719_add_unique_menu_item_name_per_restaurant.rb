class AddUniqueMenuItemNamePerRestaurant < ActiveRecord::Migration[8.0]
  def change
    add_index :menu_items, :name, unique: true
  end
end
