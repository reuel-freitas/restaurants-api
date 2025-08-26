require 'rails_helper'

RSpec.describe Menu, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:menu_items) }
  end

  describe 'attributes' do
    let(:menu) { build(:menu) }

    it 'has a name' do
      expect(menu.name).to be_present
    end

    it 'can have multiple menu items' do
      menu_item1 = create(:menu_item, name: 'Burger')
      menu_item2 = create(:menu_item, name: 'Salad')
      
      MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)

      expect(menu.menu_items.count).to eq(2)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:menu)).to be_valid
    end
  end
end
