FactoryBot.define do
  factory :pantry_item, class: 'PantryManager::PantryItem' do
    ingredient
    notes { nil }

    trait :with_notes do
      notes { "Store in a cool, dry place" }
    end

    trait :expiring_soon do
      notes { "Use by end of week" }
    end

    trait :bulk_item do
      notes { "Bought in bulk from Costco" }
    end

    trait :homemade do
      notes { "Homemade batch" }
    end
  end
end
