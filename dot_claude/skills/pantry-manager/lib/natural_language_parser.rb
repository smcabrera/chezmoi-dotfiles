require 'net/http'
require 'json'
require 'uri'

module PantryManager
  class NaturalLanguageParser
    API_ENDPOINT = 'https://api.anthropic.com/v1/messages'
    MODEL = 'claude-3-haiku-20240307'

    class ParseError < StandardError; end
    class APIError < StandardError; end

    def self.parse(text)
      api_key = ENV['ANTHROPIC_API_KEY']

      unless api_key
        raise ParseError, "ANTHROPIC_API_KEY environment variable not set"
      end

      prompt = build_prompt(text)
      response = call_api(api_key, prompt)
      parse_response(response)
    end

    private

    def self.build_prompt(text)
      <<~PROMPT
        Parse the following natural language input into a structured list of pantry items.

        Input: "#{text}"

        Extract each item with its quantity, unit, and name. Be precise about units - 'bag', 'bunch', 'container' are meaningful and should be preserved.

        Return ONLY a JSON array with this exact structure (no other text):
        [
          {"name": "item name", "quantity": "number", "unit": "unit"},
          {"name": "item name", "quantity": "number", "unit": "unit"}
        ]

        Rules:
        - Convert word numbers to digits (e.g., "four" -> "4")
        - Preserve specific units like "bag", "bunch", "container", "can", "jar", etc.
        - Use "whole" for items counted individually without other units
        - Keep item names descriptive (e.g., "roma tomatoes" not just "tomatoes")
        - Default quantity to "1" if not specified
        - Return empty array [] if no items found

        Examples:
        Input: "four roma tomatoes and a bag of kale"
        Output: [{"name": "roma tomatoes", "quantity": "4", "unit": "whole"}, {"name": "kale", "quantity": "1", "unit": "bag"}]

        Input: "2 cans of crushed tomatoes"
        Output: [{"name": "crushed tomatoes", "quantity": "2", "unit": "can"}]

        Now parse the input above and return ONLY the JSON array.
      PROMPT
    end

    def self.call_api(api_key, prompt)
      uri = URI(API_ENDPOINT)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['x-api-key'] = api_key
      request['anthropic-version'] = '2023-06-01'

      request.body = {
        model: MODEL,
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ]
      }.to_json

      response = http.request(request)

      unless response.code == '200'
        error_msg = begin
          JSON.parse(response.body)['error']['message']
        rescue
          response.body
        end
        raise APIError, "API request failed (#{response.code}): #{error_msg}"
      end

      response.body
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise APIError, "API request timed out: #{e.message}"
    rescue StandardError => e
      raise APIError, "API request failed: #{e.message}"
    end

    def self.parse_response(response_body)
      data = JSON.parse(response_body)

      # Extract the text content from Claude's response
      content = data.dig('content', 0, 'text')
      unless content
        raise ParseError, "Unexpected API response format"
      end

      # Claude might wrap the JSON in markdown code blocks, so strip those
      content = content.strip
      content = content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
      content = content.strip

      # Parse the JSON array
      items = JSON.parse(content)

      unless items.is_a?(Array)
        raise ParseError, "Expected JSON array, got #{items.class}"
      end

      # Validate each item has required fields
      items.map do |item|
        unless item.is_a?(Hash) && item['name'] && item['quantity'] && item['unit']
          raise ParseError, "Invalid item format: #{item.inspect}"
        end

        {
          name: item['name'].to_s.strip,
          quantity: item['quantity'].to_s.strip,
          unit: item['unit'].to_s.strip
        }
      end
    rescue JSON::ParserError => e
      raise ParseError, "Failed to parse API response as JSON: #{e.message}\nContent: #{content}"
    end
  end
end
