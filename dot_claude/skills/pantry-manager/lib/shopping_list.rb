module PantryManager
  class ShoppingList
    def self.generate(selected_recipes, pantry_items)
      # Collect all ingredients from selected recipes
      all_ingredients = selected_recipes.flat_map { |r| r[:ingredients] }.uniq

      # Filter out what's already in pantry
      needed = all_ingredients - pantry_items

      # Group by frequency (how many recipes use it)
      frequency = Hash.new(0)
      selected_recipes.each do |recipe|
        recipe[:ingredients].each { |ing| frequency[ing] += 1 }
      end

      {
        needed: needed.sort_by { |ing| -frequency[ing] },  # Sort by most-used first
        frequency: frequency.select { |ing, _| needed.include?(ing) }
      }
    end

    def self.list
      ShoppingListItem.includes(:ingredient).all
    end

    def self.add(ingredient_name, quantity, unit, notes: nil, added_by: 'user', recipe_id: nil)
      ShoppingListItem.add_or_update(ingredient_name, quantity, unit, notes: notes, added_by: added_by, recipe_id: recipe_id)
    end

    def self.remove(ingredient_name)
      ShoppingListItem.remove_by_name(ingredient_name)
    end

    def self.buy(ingredient_name, quantity: nil, unit: nil)
      ShoppingListItem.move_to_pantry(ingredient_name, quantity: quantity, unit: unit)
    end

    def self.need(ingredient_name)
      pantry_item = PantryItem.joins(:ingredient)
        .where(ingredients: { name: ingredient_name.downcase.strip })
        .first
      return false unless pantry_item

      ShoppingListItem.add_or_update(
        ingredient_name,
        pantry_item.quantity,
        pantry_item.unit,
        added_by: 'user'
      )
      pantry_item.destroy
      true
    end

    def self.add_missing_for_recipe(recipe_id)
      recipe = Recipe.includes(recipe_ingredients: :ingredient).find(recipe_id)
      pantry_names = PantryItem.joins(:ingredient).pluck('ingredients.name').to_set

      added = []
      recipe.recipe_ingredients.each do |ri|
        next if pantry_names.include?(ri.ingredient.name)

        item = ShoppingListItem.add_or_update(
          ri.ingredient.name,
          ri.quantity,
          ri.unit,
          added_by: 'recipe',
          recipe_id: recipe_id
        )
        added << item
      end
      added
    end
  end
end
