#!/usr/bin/env ruby
require 'bundler/setup'
require 'nokogiri'
require 'json'
require 'faraday'
require 'faraday/follow_redirects'

# Test URL that failed
url = "https://cooking.nytimes.com/recipes/1023047-caramelized-shallot-pasta"

puts "Debugging parser for: #{url}"
puts "=" * 60
puts

# Fetch HTML
conn = Faraday.new do |f|
  f.response :follow_redirects
  f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (personal use)'
end

response = conn.get(url)
html = response.body

puts "Final URL: #{response.env.url}"
puts "Response headers location: #{response.headers['location']}"

puts "Response status: #{response.status}"
puts "Response size: #{html.length} bytes"
puts

# Extract __NEXT_DATA__ script tag
doc = Nokogiri::HTML(html)
next_data_script = doc.at('script#__NEXT_DATA__')

if next_data_script
  puts "✓ Found __NEXT_DATA__ script tag"
  data = JSON.parse(next_data_script.content)

  # Check structure
  puts "  Keys in data: #{data.keys.join(', ')}"

  if data['props']
    puts "  Keys in props: #{data['props'].keys.join(', ')}"

    if data['props']['pageProps']
      puts "  Keys in pageProps: #{data['props']['pageProps'].keys.join(', ')}"

      if data['props']['pageProps']['recipe']
        recipe = data['props']['pageProps']['recipe']
        puts "  ✓ Recipe data found!"
        puts "    Title: #{recipe['title']}"
        puts "    Ingredients: #{recipe['ingredients']&.length} groups"
        puts "    Steps: #{recipe['steps']&.length} groups"
      else
        puts "  ✗ No 'recipe' key in pageProps"
        puts "  Available keys: #{data['props']['pageProps'].keys.join(', ')}"

        # Try to find recipe data elsewhere
        data['props']['pageProps'].each do |key, value|
          if value.is_a?(Hash) && (value['title'] || value['ingredients'])
            puts "  Found potential recipe data in: #{key}"
            puts "    Keys: #{value.keys.join(', ')}"
          end
        end
      end
    else
      puts "  ✗ No 'pageProps' key in props"
    end
  else
    puts "  ✗ No 'props' key in data"
  end
else
  puts "✗ No __NEXT_DATA__ script tag found"
  puts "  Looking for other script tags..."

  doc.css('script').each_with_index do |script, i|
    next unless script['id'] || script['type'] == 'application/ld+json'
    puts "  Script #{i}: id=#{script['id']}, type=#{script['type']}"
  end
end
