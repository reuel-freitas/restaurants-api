require 'rails_helper'

RSpec.describe MenuItem, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }

    it 'enforces uniqueness of name at database level' do
      create(:menu_item, name: 'Burger')

      duplicate_item = build(:menu_item, name: 'Burger')
      expect { duplicate_item.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'associations' do
    it { should have_many(:menus) }
  end

  describe 'attributes' do
    let(:menu_item) { build(:menu_item) }

    it 'has a name' do
      expect(menu_item.name).to be_present
    end

    it 'can belong to multiple menus' do
      menu1 = create(:menu, name: 'Lunch')
      menu2 = create(:menu, name: 'Dinner')

      MenuMenuItem.create!(menu: menu1, menu_item: menu_item, price: 9.00)
      MenuMenuItem.create!(menu: menu2, menu_item: menu_item, price: 15.00)

      expect(menu_item.menus.count).to eq(2)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:menu_item)).to be_valid
    end
  end
end
