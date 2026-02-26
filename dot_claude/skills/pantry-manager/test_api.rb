#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# Test script to debug Anthropic API issues

api_key = ENV['ANTHROPIC_API_KEY']
unless api_key
  puts "Error: ANTHROPIC_API_KEY environment variable not set"
  exit 1
end

puts "Testing Anthropic API..."
puts "API Key (first 10 chars): #{api_key[0..9]}..."

# Try the current endpoint
endpoints = [
  'https://api.anthropic.com/v1/messages',
  'https://api.anthropic.com/v1/complete',
  'https://api.anthropic.com/v1/chat/completions'
]

models = [
  'claude-3-5-sonnet-20240620',
  'claude-3-sonnet-20240229',
  'claude-3-opus-20240229',
  'claude-3-haiku-20240307'
]

endpoints.each do |endpoint|
  puts "\nTrying endpoint: #{endpoint}"

  uri = URI(endpoint)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.set_debug_output($stdout) if ENV['DEBUG']

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request['x-api-key'] = api_key
  request['anthropic-version'] = '2023-06-01'

  # Try a minimal request
  request.body = {
    model: models.first,
    max_tokens: 100,
    messages: [
      {
        role: 'user',
        content: 'Say hello'
      }
    ]
  }.to_json

  begin
    response = http.request(request)

    puts "Response code: #{response.code}"
    puts "Response headers:"
    response.each_header do |key, value|
      puts "  #{key}: #{value}"
    end

    puts "\nResponse body:"
    puts response.body

    if response.code == '200'
      puts "\nSUCCESS! This endpoint works."
      break
    end
  rescue => e
    puts "Error: #{e.class} - #{e.message}"
  end
end

# Also try with different auth headers
puts "\n\nTrying different auth headers..."
uri = URI('https://api.anthropic.com/v1/messages')
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

auth_headers = [
  {'x-api-key' => api_key},
  {'Authorization' => "Bearer #{api_key}"},
  {'Authorization' => "x-api-key #{api_key}"}
]

auth_headers.each_with_index do |headers, i|
  puts "\nAttempt #{i + 1}: #{headers.keys.first}"

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request['anthropic-version'] = '2023-06-01'

  headers.each do |k, v|
    request[k] = v
  end

  request.body = {
    model: 'claude-3-5-sonnet-20240620',
    max_tokens: 100,
    messages: [
      {
        role: 'user',
        content: 'Say hello'
      }
    ]
  }.to_json

  response = http.request(request)
  puts "Response: #{response.code} - #{response.message}"

  if response.code != '200'
    puts "Body: #{response.body[0..200]}..." if response.body
  else
    puts "SUCCESS!"
  end
end
