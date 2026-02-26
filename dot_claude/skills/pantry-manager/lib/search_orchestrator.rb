require_relative 'recipe_search'
require_relative 'spoonacular_client'

module PantryManager
  class SearchOrchestrator
    def self.search(query: nil, ingredients: [], limit: 10)
      # Search local database first
      local_results = RecipeSearch.search_local(
        query: query,
        ingredients: ingredients,
        limit: limit
      )

      # If we have enough results, return them
      return local_results if local_results.length >= RecipeSearch::MIN_LOCAL_RESULTS

      # Otherwise, supplement with Spoonacular
      needed_count = limit - local_results.length

      api_results = if ingredients.any?
        SpoonacularClient.search_by_ingredients(ingredients, number: needed_count)
      elsif query
        SpoonacularClient.search_by_query(query, number: needed_count)
      else
        []
      end

      (local_results + (api_results || [])).take(limit)
    end
  end
end
