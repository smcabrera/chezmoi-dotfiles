require_relative 'search_orchestrator'

module PantryManager
  class MealPlanner
    def self.generate_plan(num_meals:, pantry_items: [])
      # Get pantry ingredients
      pantry = pantry_items.any? ? pantry_items : fetch_pantry_ingredients

      # Search for candidate recipes
      if pantry.empty?
        candidates = PantryManager::Recipe.limit([num_meals * 3, 30].min).map { |recipe| format_recipe(recipe) }
      else
        candidates = SearchOrchestrator.search(
          ingredients: pantry,
          limit: [num_meals * 3, 30].min
        )
      end

      return { error: "Not enough recipes found. Import more or try different ingredients." } if candidates.empty?

      # Fetch full ingredient lists for each candidate
      detailed_candidates = candidates.map do |recipe|
        fetch_recipe_details(recipe)
      end

      {
        prompt: build_selection_prompt(
          num_meals: num_meals,
          pantry: pantry,
          candidates: detailed_candidates
        ),
        candidates: detailed_candidates,
        pantry: pantry
      }
    end

    private

    def self.fetch_pantry_ingredients
      PantryManager::PantryItem.includes(:ingredient).map { |item| item.ingredient.name }
    end

    def self.format_recipe(recipe)
      {
        id: recipe.id,
        title: recipe.title,
        yield: recipe.yield_text,
        time: recipe.total_time,
        source: 'local'
      }
    end

    def self.fetch_recipe_details(recipe)
      if recipe[:source] == 'local'
        db_recipe = PantryManager::Recipe.includes(recipe_ingredients: :ingredient).find(recipe[:id])
        recipe.merge(ingredients: db_recipe.ingredients.pluck(:name))
      else
        details = SpoonacularClient.get_recipe_details(recipe[:id])
        return recipe.merge(ingredients: []) unless details

        ingredients = details['extendedIngredients'].map { |i| i['nameClean'] || i['name'] }
        recipe.merge(ingredients: ingredients)
      end
    end

    def self.build_selection_prompt(num_meals:, pantry:, candidates:)
      <<~PROMPT
        You are helping select #{num_meals} recipes that maximize ingredient reuse.

        **Pantry ingredients available:**
        #{pantry.any? ? pantry.join(', ') : '(empty pantry)'}

        **Candidate recipes:**
        #{candidates.map.with_index { |r, i| "#{i+1}. #{r[:title]}\n   Ingredients: #{r[:ingredients].join(', ')}" }.join("\n\n")}

        **Task:**
        Select exactly #{num_meals} recipes that:
        1. Use ingredients already in the pantry as much as possible
        2. Share ingredients with each other (minimize single-use ingredients)
        3. Provide variety (not all the same type of dish)

        **Output format:**
        Return a JSON object with:
        - `selected`: array of recipe numbers (1-indexed)
        - `reasoning`: brief explanation of your choices
        - `shared_ingredients`: list of ingredients used in 2+ recipes
        - `shopping_list`: ingredients needed that aren't in pantry

        Example:
        {
          "selected": [1, 3, 7],
          "reasoning": "These three recipes share red onion, garlic, and tomatoes. Recipe 1 and 3 both use basil. Only recipe 7 needs a unique ingredient (fennel).",
          "shared_ingredients": ["red onion", "garlic", "tomatoes", "basil"],
          "shopping_list": ["fennel", "chicken breast", "pasta"]
        }
      PROMPT
    end
  end
end
