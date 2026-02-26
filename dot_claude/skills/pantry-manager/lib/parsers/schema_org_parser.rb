require 'nokogiri'
require 'json'
require 'faraday'
require 'faraday/follow_redirects'

module PantryManager
  module Parsers
    class SchemaOrgParser
      def self.can_parse?(url)
        # Try schema.org as fallback for any URL
        true
      end

      def self.parse(url)
        conn = Faraday.new do |f|
          f.response :follow_redirects
          f.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        end
        response = conn.get(url)
        html = response.body
        doc = Nokogiri::HTML(html)

        # Find <script type="application/ld+json">
        json_ld_scripts = doc.css('script[type="application/ld+json"]')

        json_ld_scripts.each do |script|
          begin
            data = JSON.parse(script.content)

            # Handle @graph structure (common in JSON-LD)
            if data['@graph']
              data = data['@graph']
            end

            # Handle array or single object
            data = [data] unless data.is_a?(Array)

            # Find recipe - @type can be a string or array of strings
            recipe_data = data.find do |item|
              type = item['@type']
              if type.is_a?(Array)
                type.include?('Recipe')
              else
                type == 'Recipe'
              end
            end
            next unless recipe_data

            return {
              source_url: url,
              title: recipe_data['name'],
              yield: recipe_data['recipeYield'],
              total_time: recipe_data['totalTime'],
              ingredients: extract_ingredients(recipe_data['recipeIngredient']),
              steps: extract_steps(recipe_data['recipeInstructions']),
              raw_data: recipe_data.to_json
            }
          rescue JSON::ParserError
            next
          end
        end

        nil  # No schema.org recipe found
      end

      private

      def self.extract_ingredients(ingredients)
        return [] unless ingredients

        # Schema.org ingredients are typically just an array of strings
        ingredients.is_a?(Array) ? ingredients : []
      end

      def self.extract_steps(instructions)
        return [] unless instructions

        # Instructions can be array of strings or array of HowToStep objects
        if instructions.is_a?(String)
          [instructions]
        elsif instructions.first.is_a?(String)
          instructions
        elsif instructions.first.is_a?(Hash)
          instructions.map { |step| step['text'] || step['description'] }.compact
        else
          []
        end
      end
    end
  end
end
