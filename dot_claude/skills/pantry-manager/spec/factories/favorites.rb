FactoryBot.define do
  factory :favorite, class: 'PantryManager::Favorite' do
    recipe
    rating { 4 }
    notes { nil }

    trait :five_star do
      rating { 5 }
      notes { "Absolutely delicious! A family favorite." }
    end

    trait :three_star do
      rating { 3 }
      notes { "Good recipe, but needs some adjustments." }
    end

    trait :one_star do
      rating { 1 }
      notes { "Not great, wouldn't make again." }
    end

    trait :with_detailed_notes do
      notes { "Made this for dinner last night. The kids loved it! Next time I'll add more garlic and reduce the salt." }
    end

    trait :quick_meal do
      rating { 5 }
      notes { "Perfect for busy weeknights!" }
    end
  end
end
