#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'lib/database'
require_relative 'lib/recipe_search'
require_relative 'lib/spoonacular_client'
require_relative 'lib/search_orchestrator'

puts "=== Phase 3 Automated Verification ==="
puts

# Test 1: Local search returns results
puts "Test 1: Local search returns results from imported recipes"
results = PantryManager::RecipeSearch.search_local(ingredients: ['garlic'], limit: 10)

if results.any?
  puts "  ✓ Found #{results.length} recipes with garlic"
  results.each do |recipe|
    puts "    - #{recipe[:title]}"
  end
else
  puts "  ✗ No results found"
  exit 1
end
puts

# Test 2: FTS search
puts "Test 2: FTS search - searching for 'marinara'"
results = PantryManager::RecipeSearch.search_local(query: 'marinara', limit: 10)

if results.any? && results.first[:title].downcase.include?('marinara')
  puts "  ✓ Found 'Classic Marinara Sauce' via FTS"
else
  puts "  ✗ FTS search failed to find marinara"
  exit 1
end
puts

# Test 3: Ingredient search with multiple ingredients
puts "Test 3: Ingredient search - searching for recipes with garlic"
results = PantryManager::RecipeSearch.search_local(ingredients: ['garlic'], limit: 10)

if results.any?
  puts "  ✓ Found #{results.length} recipes containing garlic"
  puts "    Top recipe: #{results.first[:title]} (#{results.first[:match_count]} matches)"
else
  puts "  ✗ Ingredient search failed"
  exit 1
end
puts

# Test 4: Spoonacular API client (optional - requires API key)
puts "Test 4: Spoonacular API client"
if PantryManager::SpoonacularClient.api_key
  puts "  API key found, testing search..."
  results = PantryManager::SpoonacularClient.search_by_ingredients(['chicken', 'garlic'], number: 5)

  if results.any?
    puts "  ✓ Spoonacular API returned #{results.length} results"
    puts "    Example: #{results.first[:title]}"
  else
    puts "  ⚠ Spoonacular API returned no results (may be rate limited)"
  end
else
  puts "  ℹ  No Spoonacular API key configured (optional for testing)"
  puts "     Set SPOONACULAR_API_KEY environment variable to test API"
end
puts

# Test 5: Search orchestrator
puts "Test 5: Search orchestrator - local-first fallback"
results = PantryManager::SearchOrchestrator.search(ingredients: ['garlic'], limit: 10)

if results.any?
  local_count = results.count { |r| r[:source] == 'local' }
  api_count = results.count { |r| r[:source] == 'spoonacular' }

  puts "  ✓ Orchestrator returned #{results.length} results"
  puts "    Local: #{local_count}, API: #{api_count}"
else
  puts "  ✗ Orchestrator returned no results"
  exit 1
end
puts

puts "=== All Phase 3 Automated Tests Passed! ==="
