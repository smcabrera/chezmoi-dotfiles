#!/usr/bin/env ruby
require 'bundler/setup'
require 'nokogiri'
require 'json'
require 'faraday'
require 'faraday/follow_redirects'

url = "https://www.budgetbytes.com/garlic-butter-baked-chicken-thighs/"

puts "Debugging schema.org parser for: #{url}"
puts "=" * 60
puts

# Fetch HTML
conn = Faraday.new do |f|
  f.response :follow_redirects
  f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
end

response = conn.get(url)
html = response.body

puts "Response status: #{response.status}"
puts "Response size: #{html.length} bytes"
puts

# Find JSON-LD scripts
doc = Nokogiri::HTML(html)
json_ld_scripts = doc.css('script[type="application/ld+json"]')

puts "Found #{json_ld_scripts.length} JSON-LD script tags"
puts

json_ld_scripts.each_with_index do |script, i|
  puts "Script #{i+1}:"
  begin
    data = JSON.parse(script.content)

    puts "  Root keys: #{data.keys.join(', ')}"
    puts "  Root @type: #{data['@type']}"

    # Check for @graph structure
    if data['@graph']
      puts "  Found @graph with #{data['@graph'].length} items"
      data['@graph'].each_with_index do |item, j|
        type = item['@type']
        type_str = type.is_a?(Array) ? type.join(', ') : type
        puts "    Graph item #{j+1}: @type = #{type_str}"

        # Check if this is a Recipe
        is_recipe = if type.is_a?(Array)
          type.include?('Recipe')
        else
          type == 'Recipe'
        end

        if is_recipe
          puts "      ✓ Found Recipe!"
          puts "      Name: #{item['name']}"
          puts "      Ingredients: #{item['recipeIngredient']&.length} items"
        end
      end
    else
      # Handle array or single object
      data = [data] unless data.is_a?(Array)

      data.each_with_index do |item, j|
        type = item['@type']
        type_str = type.is_a?(Array) ? type.join(', ') : type
        puts "  Item #{j+1}: @type = #{type_str}"

        # Check if this is a Recipe
        is_recipe = if type.is_a?(Array)
          type.include?('Recipe')
        else
          type == 'Recipe'
        end

        if is_recipe
          puts "    ✓ Found Recipe!"
          puts "    Name: #{item['name']}"
          puts "    Ingredients: #{item['recipeIngredient']&.length} items"
        end
      end
    end
  rescue JSON::ParserError => e
    puts "  ✗ JSON parse error: #{e.message}"
  end
  puts
end
