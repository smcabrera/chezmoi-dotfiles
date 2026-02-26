# Pantry Manager Command Reference

Complete documentation for all `pantry-manager` commands.

## Pantry Management Commands

### add <ingredient> <quantity> <unit> [notes]

Add or update an ingredient in your pantry.

**Arguments:**
- `ingredient` - Name of the ingredient (use quotes if it contains spaces)
- `quantity` - Numeric amount
- `unit` - Unit of measurement (whole, bag, cup, lb, oz, etc.)
- `notes` - Optional notes (e.g., "organic", "from farmer's market")

**Examples:**
```bash
pantry-manager add "red onion" 2 whole
pantry-manager add spinach 1 bag
pantry-manager add "olive oil" 2 cups "extra virgin"
pantry-manager add salmon 2 fillets
```

### list

Show all items currently in your pantry.

**Example:**
```bash
pantry-manager list
```

**Output:**
```
Current Pantry:

- kale: 1 bag
- red onion: 2 whole
- salmon: 2 fillets
- spinach: 1 bag
```

### remove <ingredient>

Remove an ingredient from your pantry.

**Arguments:**
- `ingredient` - Name of the ingredient to remove

**Examples:**
```bash
pantry-manager remove "red onion"
pantry-manager remove spinach
```

## Recipe Management Commands

### recipes

List all recipes that have been imported into your collection.

**Example:**
```bash
pantry-manager recipes
```

**Output:**
```
Imported Recipes:

1. Classic Marinara Sauce
   Time: 25 minutes | Yield: 3 1/2 cups
   Source: https://cooking.nytimes.com/recipes/1015987

2. Sticky Coconut Chicken and Rice
   Time: 45 minutes | Yield: 4 servings
   Source: https://cooking.nytimes.com/recipes/1023047
```

### recipe <id>

Show detailed information for a specific recipe, including ingredients and instructions.

**Arguments:**
- `id` - Recipe ID number (from the recipes list)

**Example:**
```bash
pantry-manager recipe 1
```

**Output:**
```
Classic Marinara Sauce
Time: 25 minutes | Yield: 3 1/2 cups

Ingredients:
- 1/4 cup extra-virgin olive oil
- 7 garlic cloves, peeled and slivered
- 1 (28-ounce) can whole tomatoes
- Salt to taste
- 1 sprig fresh basil

Instructions:
1. Put oil and garlic in a large skillet...
2. Cook until garlic is lightly golden...
[etc.]

Source: https://cooking.nytimes.com/recipes/1015987
```

### import <url>

Import a recipe from a URL. Supports NYT Cooking, Budget Bytes, and other sites with Schema.org markup.

**Arguments:**
- `url` - URL of the recipe to import

**Rate Limiting:** One recipe at a time with 2-second delay between imports.

**Legal Notice:** NYT Cooking imports are for personal, non-commercial use only.

**Examples:**
```bash
pantry-manager import "https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce"
pantry-manager import "https://www.budgetbytes.com/garlic-butter-baked-chicken-thighs/"
```

**Output:**
```
Importing recipe from https://cooking.nytimes.com/recipes/1015987
(2-second rate limit for respectful access)
⚠️  Personal use only - do not distribute recipe data

✅ Successfully imported: Classic Marinara Sauce
   Recipe ID: 5
   Ingredients: 5
   Parser: nyt_cooking
```

### search <query>

Search your recipe collection by title or ingredients.

**Arguments:**
- `query` - Search term (recipe title or ingredient name)

**Examples:**
```bash
pantry-manager search chicken
pantry-manager search coconut
pantry-manager search marinara
```

**Output:**
```
Search Results for "chicken":

2. Sticky Coconut Chicken and Rice
   Time: 45 minutes | Yield: 4 servings

4. Baked Garlic Butter Chicken Thighs
   Time: N/A | Yield: 5 servings
```

### favorite <recipe_id> [rating] [notes]

Mark a recipe as a favorite with optional rating and notes.

**Arguments:**
- `recipe_id` - ID of the recipe
- `rating` - Optional rating from 1-5 stars
- `notes` - Optional notes about why you like it

**Examples:**
```bash
pantry-manager favorite 1
pantry-manager favorite 2 5
pantry-manager favorite 3 4 "Kids loved this!"
```

## Meal Planning Commands

### plan <N>

Generate a meal plan with N meals that optimizes ingredient reuse.

**Arguments:**
- `N` - Number of meals to plan (e.g., 3, 5, 7)

**Example:**
```bash
pantry-manager plan 3
```

**Output:**
```
Meal Plan (3 meals):

1. Classic Marinara Sauce
   Shared ingredients: tomatoes, garlic, olive oil

2. Sticky Coconut Chicken and Rice
   Shared ingredients: garlic, rice

3. Baba Ghanouj
   Shared ingredients: olive oil, garlic

Shopping List:
✓ Already have:
  - garlic (used in all 3 recipes)
  - olive oil (used in 3 recipes)

✗ Need to buy:
  - 1 (28 oz) can whole tomatoes (marinara)
  - 2 lbs chicken thighs (coconut chicken)
  - 1 large eggplant (baba ghanouj)
  - 1 can coconut milk (coconut chicken)
  - 2 cups rice (coconut chicken)
```

## Utility Commands

### help

Show all available commands and basic usage.

**Example:**
```bash
pantry-manager help
```

## Database Location

All data is stored at: `~/.local/share/pantry-manager/pantry.db`

This SQLite database contains:
- Your pantry inventory
- Imported recipes with ingredients and instructions
- Recipe favorites and ratings
- Ingredient relationships for meal planning
