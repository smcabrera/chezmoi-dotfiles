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
          next
        end
      end

      return { error: "Could not parse recipe from #{url}" } unless recipe_data

      # Check if recipe already exists
      existing = PantryManager::Recipe.find_by(source_url: url)
      return { error: "Recipe already imported", recipe_id: existing.id } if existing

      # Create recipe with ingredients in a transaction
      recipe = nil
      ingredient_count = 0

      ActiveRecord::Base.transaction do
        recipe = PantryManager::Recipe.create!(
          source_url: recipe_data[:source_url],
          title: recipe_data[:title],
          yield_text: recipe_data[:yield],
          total_time: recipe_data[:total_time],
          raw_data: recipe_data[:raw_data]
        )

        # Parse and store ingredients
        recipe_data[:ingredients].each do |ing_text|
          parsed = IngredientParser.parse(ing_text)
          next if parsed[:name].empty?

          ingredient = PantryManager::Ingredient.find_or_create_by!(name: parsed[:name])
          
          PantryManager::RecipeIngredient.create!(
            recipe: recipe,
            ingredient: ingredient,
            quantity: parsed[:quantity],
            unit: parsed[:unit],
            original_text: parsed[:original]
          )
          
          ingredient_count += 1
        end
      end

      {
        success: true,
        recipe_id: recipe.id,
        title: recipe.title,
        ingredient_count: ingredient_count,
        parser: parser_used
      }
    rescue ActiveRecord::RecordInvalid => e
      { error: "Validation failed: #{e.message}" }
    end

    def self.from_spoonacular(spoonacular_id)
      details = SpoonacularClient.get_recipe_details(spoonacular_id)
      return { error: "Recipe not found on Spoonacular" } unless details

      source_url = details['sourceUrl'] || "https://spoonacular.com/recipes/#{spoonacular_id}"

      existing = PantryManager::Recipe.find_by(source_url: source_url)
      return { error: "Recipe already imported", recipe_id: existing.id } if existing

      recipe = nil
      ingredient_count = 0

      ActiveRecord::Base.transaction do
        recipe = PantryManager::Recipe.create!(
          source_url: source_url,
          title: details['title'],
          yield_text: "#{details['servings']} servings",
          total_time: details['readyInMinutes'] ? "#{details['readyInMinutes']} minutes" : nil,
          raw_data: details.to_json
        )

        (details['extendedIngredients'] || []).each do |ing|
          parsed = IngredientParser.parse(ing['original'])
          next if parsed[:name].empty?

          ingredient = PantryManager::Ingredient.find_or_create_by!(name: parsed[:name])
          PantryManager::RecipeIngredient.create!(
            recipe: recipe,
            ingredient: ingredient,
            quantity: parsed[:quantity],
            unit: parsed[:unit],
            original_text: parsed[:original]
          )
          ingredient_count += 1
        end
      end

      { success: true, recipe_id: recipe.id, title: recipe.title, ingredient_count: ingredient_count, parser: 'spoonacular' }
    rescue ActiveRecord::RecordInvalid => e
      { error: "Validation failed: #{e.message}" }
    end
  end
end
