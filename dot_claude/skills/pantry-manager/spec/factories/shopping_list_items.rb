FactoryBot.define do
  factory :shopping_list_item, class: 'PantryManager::ShoppingListItem' do
    ingredient
    quantity { '1' }
    unit { 'whole' }
    notes { nil }
    added_by { 'user' }
    recipe_id { nil }
  end
end
