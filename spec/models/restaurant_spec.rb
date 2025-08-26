require 'rails_helper'

RSpec.describe Restaurant, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { should have_many(:menus).dependent(:destroy) }
    it { should have_many(:menu_items).through(:menus) }
  end

  describe 'attributes' do
    let(:restaurant) { build(:restaurant) }

    it 'has a name' do
      expect(restaurant.name).to be_present
    end

    it 'can have multiple menus' do
      restaurant = create(:restaurant)
      menu1 = create(:menu, restaurant: restaurant, name: 'Lunch')
      menu2 = create(:menu, restaurant: restaurant, name: 'Dinner')

      expect(restaurant.menus.count).to eq(2)
      expect(restaurant.menus).to include(menu1, menu2)
    end

    it 'can have menu items through menus' do
      restaurant = create(:restaurant)
      menu = create(:menu, restaurant: restaurant)
      menu_item1 = create(:menu_item, name: 'Burger')
      menu_item2 = create(:menu_item, name: 'Salad')

      MenuMenuItem.create!(menu: menu, menu_item: menu_item1, price: 9.00)
      MenuMenuItem.create!(menu: menu, menu_item: menu_item2, price: 5.00)

      expect(restaurant.menu_items.count).to eq(2)
      expect(restaurant.menu_items).to include(menu_item1, menu_item2)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:restaurant)).to be_valid
    end
  end
end
