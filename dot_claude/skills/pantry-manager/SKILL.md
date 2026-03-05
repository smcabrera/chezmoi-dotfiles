---
name: pantry-manager
description: Manage pantry inventory and plan meals with maximum ingredient reuse. Use when managing ingredients, searching recipes, or planning meals.
argument-hint: "[what you want to do]"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Pantry Manager

Manage pantry inventory, recipes, and meal plans using markdown files.

## Data Location

All data lives in `~/Dropbox/GoatBot/cooking/`:

- `pantry.md` — Current pantry inventory
- `shopping-list.md` — Shopping checklist
- `recipes/` — One markdown file per recipe
- `meal-plans/` — Generated meal plans

## Operations

### Add to Pantry
Read `pantry.md`, find the right category section, add the ingredient line.
Format: `- <ingredient>: <quantity> <unit>` or `- <ingredient>` for staples.
If no matching category exists, create one.

### View Pantry
Read and display `pantry.md`.

### Remove from Pantry
Read `pantry.md`, find and remove the ingredient line.

### Import Recipe
Run: `ruby ~/.claude/skills/pantry-manager/bin/import-recipe "<url>"`
This creates a markdown file in `recipes/`.
Remind user: personal, non-commercial use only for NYT recipes.

### Search Recipes
First search locally: use Grep to search `recipes/*.md` for ingredients or titles.
If local search has no good results, search Spoonacular by ingredients:
Run: `ruby ~/.claude/skills/pantry-manager/bin/search-recipes <ingredient1> <ingredient2> ...`
This outputs tab-separated results: `<id>\t<title>\t(uses X of yours, needs Y more)`
Present results to the user. When they pick one, import it with `import-spoonacular`.

### Find New Recipes
Search Spoonacular for recipes matching the user's pantry or requested ingredients:
Run: `ruby ~/.claude/skills/pantry-manager/bin/search-recipes <ingredients>`
Present results with title and ingredient match info. When the user picks one:
Run: `ruby ~/.claude/skills/pantry-manager/bin/import-spoonacular <id>`
This fetches full recipe details and writes a markdown file to `recipes/`.

### Plan Meals
1. Read `pantry.md` to get available ingredients
2. Read all recipe files (Glob `recipes/*.md`, Read each)
3. For each recipe, extract the ingredients list
4. Select N recipes that:
   - Use pantry ingredients as much as possible
   - Share ingredients with each other
   - Provide variety
5. Write meal plan to `meal-plans/<date>.md`
6. Generate shopping list: ingredients needed minus pantry
7. Write or update `shopping-list.md`

### Shopping List
Read `shopping-list.md`. Can also:
- Add items manually
- Check off items (change `- [ ]` to `- [x]`)
- Move checked items to pantry (edit both files)

### Buy (Move Shopping -> Pantry)
Read `shopping-list.md`, find checked items, add them to `pantry.md`,
remove them from shopping list.

## Response Style

Be conversational. When showing pantry, suggest what could be made.
When planning meals, explain ingredient reuse reasoning.
When showing shopping list, group by store section if possible.

## Legal Notice

NYT Cooking imports are for personal, non-commercial use only.
One recipe at a time, with rate limiting.
