FactoryBot.define do
  factory :recipe, class: 'PantryManager::Recipe' do
    sequence(:title) { |n| "Recipe #{n}" }
    sequence(:source_url) { |n| "https://example.com/recipe-#{n}" }
    yield_text { "4 servings" }
    total_time { "30 minutes" }

    trait :with_ingredients do
      transient do
        ingredient_count { 3 }
      end

      after(:create) do |recipe, evaluator|
        create_list(:recipe_ingredient, evaluator.ingredient_count, recipe: recipe)
      end
    end

    trait :favorite do
      after(:create) do |recipe|
        create(:favorite, recipe: recipe)
      end
    end
  end
end
