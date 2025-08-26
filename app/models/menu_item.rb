class MenuItem < ApplicationRecord
  has_many :menu_menu_items, dependent: :destroy
  has_many :menus, through: :menu_menu_items

  validates :name, presence: true

  def price_for_menu(menu)
    menu_menu_items.find_by(menu: menu)&.price
  end
end
