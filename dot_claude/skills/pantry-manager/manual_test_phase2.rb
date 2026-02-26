#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'lib/database'
require_relative 'lib/models'
require_relative 'lib/recipe_importer'

puts "=== Phase 2 Manual Verification ==="
puts
puts "⚠️  LEGAL DISCLAIMER:"
puts "Testing NYT Cooking recipe import for personal, non-commercial use only."
puts "Rate limited to one recipe at a time with 2-second delay."
puts

# Test recipe URLs
nyt_recipes = [
  "https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce",
  "https://cooking.nytimes.com/recipes/1023047-sticky-coconut-chicken-and-rice", # This URL may redirect
  "https://cooking.nytimes.com/recipes/1014030-scrambled-eggs"
]

schema_org_recipes = [
  "https://www.allrecipes.com/recipe/23600/worlds-best-lasagna/",
  "https://www.budgetbytes.com/garlic-butter-baked-chicken-thighs/"
]

# Test 1: Import NYT Cooking recipes
puts "Test 1: Import 3 NYT Cooking recipes"
puts "-" * 60

nyt_recipes.each_with_index do |url, i|
  print "  Importing recipe #{i+1}/3... "
  result = PantryManager::RecipeImporter.import(url)

  if result[:success]
    puts "✓"
    puts "    Title: #{result[:title]}"
    puts "    Ingredients: #{result[:ingredient_count]}"
    puts "    Parser: #{result[:parser]}"
  else
    puts "✗"
    puts "    Error: #{result[:error]}"
  end

  # Rate limiting: 2 seconds between requests
  sleep 2 if i < nyt_recipes.length - 1
  puts
end

puts

# Test 2: Import schema.org recipes
puts "Test 2: Import 2 schema.org recipes from other sites"
puts "-" * 60

schema_org_recipes.each_with_index do |url, i|
  print "  Importing recipe #{i+1}/2... "
  result = PantryManager::RecipeImporter.import(url)

  if result[:success]
    puts "✓"
    puts "    Title: #{result[:title]}"
    puts "    Ingredients: #{result[:ingredient_count]}"
    puts "    Parser: #{result[:parser]}"
  else
    puts "✗"
    puts "    Error: #{result[:error]}"
  end

  sleep 1 if i < schema_org_recipes.length - 1
  puts
end

puts

# Test 3: Check database for duplicate handling
puts "Test 3: Duplicate handling - re-import first recipe"
puts "-" * 60

first_url = nyt_recipes.first
print "  Re-importing: #{first_url}... "
result = PantryManager::RecipeImporter.import(first_url)

if result[:error] && result[:error].include?("already imported")
  puts "✓"
  puts "    Correctly rejected duplicate"
  puts "    Message: #{result[:error]}"
else
  puts "✗"
  puts "    Should have rejected duplicate!"
  puts "    Result: #{result.inspect}"
end

puts
puts

# Test 4: Verify ingredient normalization
puts "Test 4: Ingredient normalization verification"
puts "-" * 60

db = PantryManager::Database.connection

# Find ingredients with "onion" in the name
onions = db.execute(
  "SELECT DISTINCT name FROM ingredients WHERE name LIKE '%onion%' OR name LIKE '%shallot%'"
)

if onions.any?
  puts "  Onion/shallot ingredients found:"
  onions.each do |row|
    puts "    - '#{row['name']}'"
  end
  puts
  puts "  ✓ Verify these are normalized (no 'diced', 'chopped', etc.)"
else
  puts "  ℹ  No onion/shallot ingredients found in imported recipes"
end

puts
puts

# Summary statistics
puts "Summary Statistics"
puts "-" * 60

recipe_count = db.execute("SELECT COUNT(*) as count FROM recipes").first['count']
ingredient_count = db.execute("SELECT COUNT(*) as count FROM ingredients").first['count']

puts "  Total recipes imported: #{recipe_count}"
puts "  Unique ingredients: #{ingredient_count}"

# Show all recipes
puts
puts "  All imported recipes:"
recipes = db.execute("SELECT id, title FROM recipes")
recipes.each do |recipe|
  ing_count = db.execute(
    "SELECT COUNT(*) as count FROM recipe_ingredients WHERE recipe_id = ?",
    [recipe['id']]
  ).first['count']

  puts "    #{recipe['id']}. #{recipe['title']} (#{ing_count} ingredients)"
end

puts
puts "=== Phase 2 Manual Verification Complete ==="
puts
puts "Next steps:"
puts "- Review ingredients in database to verify normalization quality"
puts "- Check that duplicate import was rejected"
puts "- Verify both NYT and schema.org parsers worked correctly"
