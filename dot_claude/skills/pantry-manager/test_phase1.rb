#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'lib/database'
require_relative 'lib/models'
require_relative 'lib/cli'

puts "=== Phase 1 Automated Verification ==="
puts

# Test 1: Database creation
puts "Test 1: Database file creation"
db_path = PantryManager::Database::DB_PATH

# Initialize database connection (this creates the file)
db = PantryManager::Database.connection

if File.exist?(db_path)
  puts "  ✓ Database exists at #{db_path}"
else
  puts "  ✗ Database does not exist at #{db_path}"
  exit 1
end
puts

# Test 2: Schema verification
puts "Test 2: Schema verification"

expected_tables = ['recipes', 'ingredients', 'recipe_ingredients', 'pantry', 'favorites', 'recipes_fts']
tables = db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").map { |row| row['name'] }

expected_tables.each do |table|
  if tables.include?(table)
    puts "  ✓ Table '#{table}' exists"
  else
    puts "  ✗ Table '#{table}' missing"
    exit 1
  end
end
puts

# Test 3: Pantry add command
puts "Test 3: Pantry add command"
PantryManager::PantryItem.add("red onion", "1", "whole")
items = PantryManager::PantryItem.all
if items.any? { |item| item.ingredient_name == "red onion" }
  puts "  ✓ Added 'red onion' to pantry"
else
  puts "  ✗ Failed to add 'red onion' to pantry"
  exit 1
end
puts

# Test 4: Pantry list command
puts "Test 4: Pantry list command"
output = PantryManager::CLI.format_pantry_list(items)
if output.include?("red onion")
  puts "  ✓ List command shows pantry items"
else
  puts "  ✗ List command failed"
  exit 1
end
puts

puts "=== All Phase 1 Automated Tests Passed! ==="
puts
puts "Output from pantry list:"
puts output
