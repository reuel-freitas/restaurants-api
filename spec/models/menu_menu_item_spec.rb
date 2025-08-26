require 'rails_helper'

RSpec.describe MenuMenuItem, type: :model do
  describe 'associations' do
    it { should belong_to(:menu) }
    it { should belong_to(:menu_item) }
  end

  describe 'validations' do
    it { should validate_presence_of(:menu) }
    it { should validate_presence_of(:menu_item) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than(0) }
  end

  describe 'uniqueness' do
    let(:menu) { create(:menu) }
    let(:menu_item) { create(:menu_item) }

    it 'enforces unique menu-item combinations' do
      MenuMenuItem.create!(menu: menu, menu_item: menu_item, price: 9.00)

      duplicate = MenuMenuItem.new(menu: menu, menu_item: menu_item, price: 10.00)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:menu_item_id]).to include('has already been taken')
    end
  end

  describe 'price handling' do
    let(:menu) { create(:menu) }
    let(:menu_item) { create(:menu_item) }

    it 'accepts valid prices' do
      menu_menu_item = MenuMenuItem.new(menu: menu, menu_item: menu_item, price: 9.99)
      expect(menu_menu_item).to be_valid
    end

    it 'rejects zero prices' do
      menu_menu_item = MenuMenuItem.new(menu: menu, menu_item: menu_item, price: 0)
      expect(menu_menu_item).not_to be_valid
    end

    it 'rejects negative prices' do
      menu_menu_item = MenuMenuItem.new(menu: menu, menu_item: menu_item, price: -5.00)
      expect(menu_menu_item).not_to be_valid
    end
  end
end
