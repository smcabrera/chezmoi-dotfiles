#!/usr/bin/env ruby

# Manual test script for natural language parsing feature
# This tests the actual API integration (requires ANTHROPIC_API_KEY)

require_relative 'lib/database'
require_relative 'lib/models'
require_relative 'lib/natural_language_parser'

def test_parsing
  puts "Testing Natural Language Parser"
  puts "=" * 50
  puts

  unless ENV['ANTHROPIC_API_KEY']
    puts "ERROR: ANTHROPIC_API_KEY environment variable not set"
    puts "Please set it to test the natural language parsing feature."
    puts
    puts "Example:"
    puts "  export ANTHROPIC_API_KEY='your-key-here'"
    puts "  ruby test_natural_language.rb"
    exit 1
  end

  test_cases = [
    "four roma tomatoes and a bag of kale",
    "2 cans of crushed tomatoes",
    "three red onions, 5 cloves of garlic, and a bunch of spinach"
  ]

  test_cases.each_with_index do |test_case, idx|
    puts "Test #{idx + 1}: #{test_case}"
    puts "-" * 50

    begin
      result = PantryManager::NaturalLanguageParser.parse(test_case)

      puts "Parsed #{result.length} item(s):"
      result.each_with_index do |item, i|
        puts "  #{i + 1}. #{item[:quantity]}x #{item[:name]} (#{item[:unit]})"
      end
      puts "✅ Success"
    rescue => e
      puts "❌ Error: #{e.class} - #{e.message}"
    end

    puts
  end
end

# Initialize database
PantryManager::Database.connection

# Run tests
test_parsing

puts "All tests completed!"
