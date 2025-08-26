class CreateMenuMenuItems < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_menu_items do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :menu_item, null: false, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
