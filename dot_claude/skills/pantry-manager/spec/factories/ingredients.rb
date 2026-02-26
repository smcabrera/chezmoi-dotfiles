FactoryBot.define do
  factory :ingredient, class: 'PantryManager::Ingredient' do
    sequence(:name) { |n| "ingredient #{n}" }

    trait :in_pantry do
      after(:create) do |ingredient|
        create(:pantry_item, ingredient: ingredient)
      end
    end

    trait :with_recipes do
      transient do
        recipe_count { 2 }
      end

      after(:create) do |ingredient, evaluator|
        create_list(:recipe_ingredient, evaluator.recipe_count, ingredient: ingredient)
      end
    end
  end
end
