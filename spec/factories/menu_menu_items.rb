FactoryBot.define do
  factory :menu_menu_item do
    association :menu
    association :menu_item
    price { rand(5.0..25.0).round(2) }
  end
end
