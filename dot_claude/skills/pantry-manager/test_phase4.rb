#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'lib/database'
require_relative 'lib/meal_planner'
require_relative 'lib/shopping_list'

puts "=== Phase 4 Automated Verification ==="
puts

# Test 1: Meal planner generates selection prompt
puts "Test 1: Meal planner generates selection prompt"
# Provide common pantry items that should match our recipes
plan_data = PantryManager::MealPlanner.generate_plan(
  num_meals: 3,
  pantry_items: ['garlic', 'salt', 'olive oil']
)

if plan_data[:error]
  puts "  ✗ Error: #{plan_data[:error]}"
  exit 1
elsif plan_data[:prompt] && plan_data[:candidates] && plan_data[:pantry]
  puts "  ✓ Generated plan data with prompt"
  puts "    Candidates: #{plan_data[:candidates].length} recipes"
  puts "    Pantry items: #{plan_data[:pantry].length}"
else
  puts "  ✗ Plan data incomplete"
  exit 1
end
puts

# Test 2: Shopping list generation
puts "Test 2: Shopping list correctly filters pantry items"

# Mock data for testing
mock_recipes = [
  { title: "Recipe 1", ingredients: ['garlic', 'onion', 'tomato'] },
  { title: "Recipe 2", ingredients: ['garlic', 'chicken', 'rice'] }
]
mock_pantry = ['garlic']

shopping_list = PantryManager::ShoppingList.generate(mock_recipes, mock_pantry)

expected_items = ['onion', 'tomato', 'chicken', 'rice'].sort
actual_items = shopping_list[:needed].sort

if actual_items == expected_items
  puts "  ✓ Shopping list correct: #{actual_items.join(', ')}"
else
  puts "  ✗ Shopping list incorrect"
  puts "    Expected: #{expected_items.join(', ')}"
  puts "    Got: #{actual_items.join(', ')}"
  exit 1
end
puts

# Test 3: Ingredient frequency calculation
puts "Test 3: Ingredient frequency calculation"
if shopping_list[:frequency]['garlic']
  puts "  ⚠  'garlic' shouldn't be in shopping list (already in pantry)"
  exit 1
end

if shopping_list[:frequency]['onion'] == 1 && shopping_list[:frequency]['rice'] == 1
  puts "  ✓ Frequency calculated correctly"
else
  puts "  ✗ Frequency calculation wrong"
  puts "    Frequencies: #{shopping_list[:frequency]}"
  exit 1
end
puts

# Test 4: Meal planner with empty pantry
puts "Test 4: Meal planner with empty pantry"
plan_data = PantryManager::MealPlanner.generate_plan(num_meals: 2, pantry_items: [])

if plan_data[:error]
  puts "  ✗ Error: #{plan_data[:error]}"
  exit 1
elsif plan_data[:pantry].empty?
  puts "  ✓ Handles empty pantry correctly"
else
  puts "  ✗ Should have empty pantry"
  exit 1
end
puts

puts "=== All Phase 4 Automated Tests Passed! ==="
puts
puts "Note: The actual meal selection logic requires Claude's AI capabilities"
puts "and will be tested during manual verification with the /pantry plan command."
