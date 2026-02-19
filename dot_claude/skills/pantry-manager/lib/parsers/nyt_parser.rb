require 'nokogiri'
require 'json'
require 'faraday'

module PantryManager
  module Parsers
    class NYTParser
      # Rate limiting: minimum 2 seconds between requests
      @last_request_time = nil
      RATE_LIMIT_SECONDS = 2

      def self.can_parse?(url)
        url.include?('cooking.nytimes.com')
      end

      def self.parse(url)
        # Enforce rate limiting
        enforce_rate_limit

        # Fetch HTML with standard user agent (not anthropic-ai)
        conn = Faraday.new do |f|
          f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (personal use)'
        end

        response = conn.get(url)
        html = response.body

        # Extract __NEXT_DATA__ script tag
        doc = Nokogiri::HTML(html)
        next_data_script = doc.at('script#__NEXT_DATA__')
        return nil unless next_data_script

        data = JSON.parse(next_data_script.content)
        recipe_data = data.dig('props', 'pageProps', 'recipe')

        return nil unless recipe_data

        # Transform to standard format
        {
          source_url: url,
          title: recipe_data['title'],
          yield: recipe_data['recipeYield'],
          total_time: recipe_data['totalTime'],
          ingredients: extract_ingredients(recipe_data['ingredients']),
          steps: extract_steps(recipe_data['steps']),
          raw_data: recipe_data.to_json
        }
      end

      private

      def self.extract_ingredients(ingredient_groups)
        # NYT has groups (e.g., "For the sauce", "For the pasta")
        # Each group has an array of ingredients with quantity + text
        return [] unless ingredient_groups

        ingredients = []
        ingredient_groups.each do |group|
          next unless group['ingredients']
          group['ingredients'].each do |ing|
            # Combine quantity and text into a single string
            full_text = [ing['quantity'], ing['text']].compact.join(' ').strip
            ingredients << full_text
          end
        end
        ingredients
      end

      def self.extract_steps(step_groups)
        return [] unless step_groups

        steps = []
        step_groups.each do |group|
          next unless group['steps']
          group['steps'].each do |step|
            steps << step['description']
          end
        end
        steps
      end

      def self.enforce_rate_limit
        if @last_request_time
          elapsed = Time.now - @last_request_time
          if elapsed < RATE_LIMIT_SECONDS
            sleep(RATE_LIMIT_SECONDS - elapsed)
          end
        end

        @last_request_time = Time.now
      end
    end
  end
end
