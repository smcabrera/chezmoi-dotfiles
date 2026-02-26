module PantryManager
  class RecipeSearch
    MIN_LOCAL_RESULTS = 5

    def self.search_local(query: nil, ingredients: [], limit: 10)
      results = []

      # Text search via FTS
      if query && !query.empty?
        results = Recipe.search_by_title(query, limit: limit)
      end

      # Ingredient-based search
      if ingredients.any?
        results = Recipe.search_by_ingredients(ingredients, limit: limit)
      end

      results.map { |recipe| format_recipe(recipe) }
    end

    def self.format_recipe(recipe)
      {
        id: recipe.id,
        title: recipe.title,
        yield: recipe.yield_text,
        time: recipe.total_time,
        source: 'local',
        match_count: recipe.try(:match_count)
      }
    end
  end
end
