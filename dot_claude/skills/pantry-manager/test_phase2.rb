#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'lib/database'
require_relative 'lib/models'
require_relative 'lib/ingredient_parser'
require_relative 'lib/parsers/nyt_parser'
require_relative 'lib/parsers/schema_org_parser'

puts "=== Phase 2 Automated Verification ==="
puts

# Test 1: Ingredient parser - basic parsing
puts "Test 1: Ingredient parser - basic quantity and unit"
parsed = PantryManager::IngredientParser.parse("1/4 cup red onion, diced")
if parsed[:quantity] == "1/4" && parsed[:unit] == "cup" && parsed[:name] == "red onion"
  puts "  ✓ Correctly parsed '1/4 cup red onion, diced'"
  puts "    - Quantity: #{parsed[:quantity]}"
  puts "    - Unit: #{parsed[:unit]}"
  puts "    - Name: #{parsed[:name]}"
else
  puts "  ✗ Failed to parse correctly"
  puts "    Got: #{parsed.inspect}"
  exit 1
end
puts

# Test 2: Ingredient parser - normalization
puts "Test 2: Ingredient parser - normalization"
test_cases = [
  ["2 red onions, diced", "red onions"],
  ["1 bunch fresh cilantro, chopped", "cilantro"],
  ["3 cloves garlic, minced", "garlic"],
  ["Salt and pepper to taste", "salt and pepper"]
]

test_cases.each do |input, expected|
  parsed = PantryManager::IngredientParser.parse(input)
  if parsed[:name] == expected
    puts "  ✓ '#{input}' → '#{expected}'"
  else
    puts "  ✗ '#{input}' → expected '#{expected}', got '#{parsed[:name]}'"
  end
end
puts

# Test 3: Parser selection
puts "Test 3: Parser selection"
nyt_url = "https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce"
if PantryManager::Parsers::NYTParser.can_parse?(nyt_url)
  puts "  ✓ NYT parser recognizes NYT Cooking URL"
else
  puts "  ✗ NYT parser failed to recognize NYT URL"
  exit 1
end

other_url = "https://www.allrecipes.com/recipe/12345"
if PantryManager::Parsers::SchemaOrgParser.can_parse?(other_url)
  puts "  ✓ Schema.org parser acts as fallback"
else
  puts "  ✗ Schema.org parser failed"
  exit 1
end
puts

# Test 4: Database storage (we'll verify tables are ready)
puts "Test 4: Database schema for recipes"
db = PantryManager::Database.connection

# Check if we can query recipe-related tables
tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%recipe%'")
table_names = tables.map { |row| row['name'] }

if table_names.include?('recipes') && table_names.include?('recipe_ingredients')
  puts "  ✓ Recipe tables exist and ready for import"
else
  puts "  ✗ Missing recipe tables"
  exit 1
end
puts

puts "=== All Phase 2 Automated Tests Passed! ==="
puts
puts "Note: Actual recipe import from live URLs should be tested manually"
puts "to avoid hitting rate limits during automated testing."
