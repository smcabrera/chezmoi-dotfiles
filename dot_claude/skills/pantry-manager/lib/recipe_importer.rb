require_relative 'parsers/nyt_parser'
require_relative 'parsers/schema_org_parser'
require_relative 'ingredient_parser'

module PantryManager
  class RecipeImporter
    PARSERS = [
      Parsers::NYTParser,
      Parsers::SchemaOrgParser
    ]

    def self.import(url)
      # Try parsers in order
      recipe_data = nil
      parser_used = nil

      PARSERS.each do |parser|
        next unless parser.can_parse?(url)

        begin
          recipe_data = parser.parse(url)
          if recipe_data
            parser_used = parser.name.split('::').last
            break
          end
        rescue => e
          # Continue to next parser if this one fails
          next
        end
      end

      return { error: "Could not parse recipe from #{url}" } unless recipe_data

      # Store in database
      db = Database.connection

      # Check if recipe already exists
      existing = db.execute("SELECT id FROM recipes WHERE source_url = ?", [url]).first
      return { error: "Recipe already imported", recipe_id: existing['id'] } if existing

      # Insert recipe
      db.execute(
        "INSERT INTO recipes (source_url, title, yield_text, total_time, raw_data) VALUES (?, ?, ?, ?, ?)",
        [recipe_data[:source_url], recipe_data[:title], recipe_data[:yield],
         recipe_data[:total_time], recipe_data[:raw_data]]
      )
      recipe_id = db.last_insert_row_id

      # Parse and store ingredients
      ingredient_count = 0
      recipe_data[:ingredients].each do |ing_text|
        parsed = IngredientParser.parse(ing_text)

        # Skip if no ingredient name extracted
        next if parsed[:name].empty?

        # Get or create ingredient
        ing_row = db.execute("SELECT id FROM ingredients WHERE name = ?", [parsed[:name]]).first
        unless ing_row
          db.execute("INSERT INTO ingredients (name) VALUES (?)", [parsed[:name]])
          ing_row = { 'id' => db.last_insert_row_id }
        end

        # Link to recipe
        db.execute(
          "INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit, original_text) VALUES (?, ?, ?, ?, ?)",
          [recipe_id, ing_row['id'], parsed[:quantity], parsed[:unit], parsed[:original]]
        )
        ingredient_count += 1
      end

      {
        success: true,
        recipe_id: recipe_id,
        title: recipe_data[:title],
        ingredient_count: ingredient_count,
        parser: parser_used
      }
    end
  end
end
