#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

puts "=== Pantry Manager API Check ==="
puts

# Check for API key
api_key = ENV['ANTHROPIC_API_KEY']

if api_key.nil? || api_key.empty?
  puts "❌ ANTHROPIC_API_KEY environment variable is not set!"
  puts
  puts "To use the natural language feature, you need to:"
  puts
  puts "1. Get an API key from https://console.anthropic.com/"
  puts
  puts "2. Set it in your environment:"
  puts "   export ANTHROPIC_API_KEY='your-api-key-here'"
  puts
  puts "3. Or add it to your shell config file (~/.bashrc, ~/.zshrc, etc.):"
  puts "   echo \"export ANTHROPIC_API_KEY='your-api-key-here'\" >> ~/.zshrc"
  puts
  puts "4. Then run the pantry-manager command again"
  puts
  exit 1
end

puts "✅ ANTHROPIC_API_KEY is set"
puts "   Key prefix: #{api_key[0..9]}..."
puts

# Test the API
puts "Testing API connection..."
puts

uri = URI('https://api.anthropic.com/v1/messages')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.read_timeout = 30

request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/json'
request['x-api-key'] = api_key
request['anthropic-version'] = '2023-06-01'

request.body = {
  model: 'claude-3-5-sonnet-20240620',
  max_tokens: 100,
  messages: [
    {
      role: 'user',
      content: 'Say "API test successful" and nothing else.'
    }
  ]
}.to_json

begin
  response = http.request(request)

  case response.code
  when '200'
    data = JSON.parse(response.body)
    content = data.dig('content', 0, 'text')
    puts "✅ API test successful!"
    puts "   Response: #{content}"
    puts
    puts "Your API key is working correctly. You can now use natural language commands:"
    puts '   bin/pantry-manager add "6 roma tomatoes"'
  when '401'
    puts "❌ Authentication failed - invalid API key"
    puts
    puts "Please check that your API key is correct and active."
  when '404'
    puts "❌ Got 404 error"
    puts
    puts "Response headers:"
    response.each_header { |k,v| puts "  #{k}: #{v}" }
    puts
    puts "Response body:"
    puts response.body
  else
    puts "❌ API request failed with code #{response.code}"
    puts
    puts "Response body:"
    puts response.body
  end
rescue => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts
  puts "This might be a network issue. Please check your internet connection."
end
