---
name: pantry
description: Manage pantry inventory and plan meals with maximum ingredient reuse
---

# Pantry Manager Skill

You are helping the user manage their pantry and plan meals with maximum ingredient reuse.

## ⚠️ IMPORTANT: Legal Disclaimer

**NYT Cooking Import**: This tool can import recipes from NYT Cooking for **personal, non-commercial use only**.
- NYT's Terms of Service prohibit automated scraping without permission
- You are using this tool at your own discretion for personal meal planning
- Do NOT use this tool to build a commercial recipe database
- Do NOT distribute imported recipe data
- If you plan to make this tool public or use it commercially, you MUST obtain permission from The New York Times first

**Rate Limiting**: NYT imports are limited to one recipe at a time with a 2-second delay to be respectful of their servers.

## Setup

When this skill is first invoked, load the required libraries:

```ruby
require_relative 'lib/database'
require_relative 'lib/models'
require_relative 'lib/cli'

# Initialize database connection
PantryManager::Database.connection
```

## Available Commands:

**Pantry Management:**
- `/pantry add <ingredient> <quantity> <unit>` - Add ingredient to pantry (e.g., "red onion" "1" "whole")
- `/pantry list` - Show current pantry state
- `/pantry remove <ingredient>` - Remove ingredient from pantry

**Recipe Management:**
- `/pantry recipes` - List all imported recipes
- `/pantry recipe <id>` - Show recipe details
- `/pantry favorite <recipe_id>` - Mark recipe as favorite (Phase 4)

**Recipe Import (Phase 2):**
- `/pantry import <url>` - Import recipe from URL (one at a time, 2-second rate limit)

**Recipe Search (Phase 3):**
- `/pantry search <query>` - Search local recipes

**Meal Planning (Phase 4):**
- `/pantry plan <N>` - Generate N-meal plan optimizing ingredient reuse

## Database Location:
`~/.local/share/pantry-manager/pantry.db`

## Implementation Notes:

### For `/pantry add`:
```ruby
ingredient_name = args[0]
quantity = args[1]
unit = args[2]
PantryManager::PantryItem.add(ingredient_name, quantity, unit)
puts "Added #{quantity} #{unit} #{ingredient_name} to pantry."
```

### For `/pantry list`:
```ruby
items = PantryManager::PantryItem.all
puts PantryManager::CLI.format_pantry_list(items)
```

### For `/pantry remove`:
```ruby
ingredient_name = args[0]
if PantryManager::PantryItem.remove(ingredient_name)
  puts "Removed #{ingredient_name} from pantry."
else
  puts "#{ingredient_name} not found in pantry."
end
```

### For `/pantry recipes`:
```ruby
recipes = PantryManager::Recipe.all
puts PantryManager::CLI.format_recipe_list(recipes)
```

### For `/pantry recipe`:
```ruby
recipe_id = args[0]
recipe = PantryManager::Recipe.find(recipe_id)
if recipe
  puts PantryManager::CLI.format_recipe_details(recipe)
else
  puts "Recipe not found."
end
```

### For `/pantry import`:
```ruby
require_relative 'lib/recipe_importer'

url = args[0]
puts "Importing recipe... (2-second rate limit for respectful access)"
puts "⚠️  This is for personal, non-commercial use only."

result = PantryManager::RecipeImporter.import(url)

if result[:success]
  puts "✓ Imported: #{result[:title]}"
  puts "  Recipe ID: #{result[:recipe_id]}"
  puts "  Ingredients: #{result[:ingredient_count]}"
else
  puts "✗ Import failed: #{result[:error]}"
end
```

### For `/pantry search`:
```ruby
require_relative 'lib/search_orchestrator'

query = args.join(' ')
results = PantryManager::SearchOrchestrator.search(query: query, limit: 10)

if results.any?
  puts "Found #{results.length} recipes:"
  results.each_with_index do |recipe, i|
    source_label = recipe[:source] == 'local' ? '' : ' (Spoonacular)'
    puts "  #{i+1}. #{recipe[:title]}#{source_label}"
  end
else
  puts "No recipes found matching '#{query}'"
end
```

### For `/pantry plan`:
```ruby
require_relative 'lib/meal_planner'
require_relative 'lib/shopping_list'

num_meals = args[0].to_i

puts "Generating #{num_meals}-meal plan..."
plan_data = PantryManager::MealPlanner.generate_plan(num_meals: num_meals)

if plan_data[:error]
  puts "Error: #{plan_data[:error]}"
else
  # Use Claude's AI capabilities to select the best recipes
  # The plan_data contains:
  # - :prompt - instructions for Claude
  # - :candidates - available recipes with ingredients
  # - :pantry - current pantry items

  # Process the selection prompt and make intelligent choices
  # Focus on:
  # 1. Recipes that use pantry ingredients
  # 2. Recipes that share ingredients with each other
  # 3. Variety in meal types

  # Example output format:
  puts "\n🍽️  #{num_meals}-Meal Plan\n"
  puts "=" * 60
  puts

  # Show selected recipes with reasoning
  # Highlight shared ingredients
  # Generate and show shopping list

  puts "\n📝 Shopping List"
  puts "-" * 60
  # Show what to buy
end
```

## Response Style

Be conversational and helpful. When showing pantry items or recipes, explain what the user has and suggest what they could make with those ingredients (once search/planning is implemented).

For recipe import (Phase 2+), remind users:
- Only one recipe at a time (no batch imports)
- Show rate limiting message: "Importing recipe... (2-second rate limit for respectful access)"
- Remind this is for personal use only

For meal planning (Phase 4+), emphasize ingredient reuse:
- Highlight shared ingredients across selected recipes
- Explain why recipes work well together
- Show shopping list clearly (what to buy vs what you have)
