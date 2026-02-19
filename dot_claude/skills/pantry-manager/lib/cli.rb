module PantryManager
  class CLI
    def self.format_pantry_list(items)
      return "Pantry is empty." if items.empty?

      output = "**Current Pantry:**\n\n"
      items.each do |item|
        quantity_str = [item.quantity, item.unit].compact.join(' ')
        notes_str = item.notes ? " (#{item.notes})" : ""
        output += "- #{item.ingredient_name}: #{quantity_str}#{notes_str}\n"
      end
      output
    end

    def self.format_recipe_list(recipes)
      return "No recipes found." if recipes.empty?

      output = "**Imported Recipes:**\n\n"
      recipes.each do |recipe|
        output += "#{recipe.id}. **#{recipe.title}**\n"
        output += "   Time: #{recipe.total_time || 'N/A'} | "
        output += "Yield: #{recipe.yield_text || 'N/A'}\n"
        output += "   Source: #{recipe.source_url}\n\n"
      end
      output
    end

    def self.format_recipe_details(recipe)
      output = "**#{recipe.title}**\n\n"
      output += "- **Yield:** #{recipe.yield_text || 'N/A'}\n"
      output += "- **Time:** #{recipe.total_time || 'N/A'}\n"
      output += "- **Source:** #{recipe.source_url}\n\n"

      ingredients = recipe.ingredients
      if ingredients.any?
        output += "**Ingredients:**\n"
        ingredients.each do |ing|
          quantity_str = [ing['quantity'], ing['unit']].compact.join(' ')
          output += "- #{quantity_str} #{ing['name']}\n"
        end
      end

      output
    end
  end
end
