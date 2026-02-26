FactoryBot.define do
  factory :recipe_ingredient, class: 'PantryManager::RecipeIngredient' do
    recipe
    ingredient
    sequence(:quantity) { |n| n.to_s }
    unit { ['cup', 'tablespoon', 'teaspoon', 'ounce', 'pound', 'gram', 'clove', 'piece'].sample }

    trait :no_quantity do
      quantity { nil }
      unit { nil }
    end

    trait :metric do
      quantity { rand(50..500).to_s }
      unit { ['gram', 'ml', 'liter', 'kilogram'].sample }
    end

    trait :imperial do
      quantity { rand(1..16).to_s }
      unit { ['cup', 'tablespoon', 'teaspoon', 'ounce', 'pound', 'quart'].sample }
    end
  end
end
