class MenuMenuItem < ApplicationRecord
  belongs_to :menu
  belongs_to :menu_item

  validates :menu, presence: true
  validates :menu_item, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :menu_item_id, uniqueness: { scope: :menu_id }
end
