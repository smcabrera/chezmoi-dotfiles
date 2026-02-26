# Pantry Manager

A command-line tool for managing your pantry inventory and planning meals with maximum ingredient reuse.

## Features

- Manage pantry inventory (add, remove, list ingredients)
- Import recipes from NYT Cooking and Schema.org sites
- Search local recipe database
- View recipe details and ingredients
- Generate meal plans optimizing ingredient reuse
- Mark favorite recipes with ratings and notes

## Installation

### Basic Usage

```bash
cd /Users/stephen/.claude/skills/pantry-manager
./bin/pantry-manager help
```

### System-wide Access (Optional)

Add the bin directory to your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="/Users/stephen/.claude/skills/pantry-manager/bin:$PATH"

# Then use from anywhere
pantry-manager list
```

## Prerequisites

- Ruby (tested with 2.7+)
- SQLite3
- Bundler
- Anthropic API key (optional, for natural language parsing)

## Setup

### Database Setup

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Run database migrations:
   ```bash
   rake db:migrate
   ```

3. For test database:
   ```bash
   RAILS_ENV=test rake db:migrate
   ```

### Natural Language Parsing (Optional)

To use natural language parsing for adding pantry items, set your Anthropic API key:

```bash
# Add to ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="your-api-key-here"
```

Without the API key, you can still use the structured format:
```bash
pantry-manager add "ingredient" quantity unit
```

### Running Tests

```bash
bundle exec rspec
```

### Database Migrations

Create a new migration:
```bash
rake db:create_migration NAME=add_something_to_table
```

Run pending migrations:
```bash
rake db:migrate
```

Rollback last migration:
```bash
rake db:rollback
```

## Usage

### Pantry Management

```bash
# Add items to your pantry - Natural language (requires ANTHROPIC_API_KEY)
pantry-manager add "four roma tomatoes and a bag of kale"
pantry-manager add "2 cans of crushed tomatoes"

# Add items to your pantry - Structured format
pantry-manager add "red onion" 2 whole
pantry-manager add spinach 1 bag "from farmer's market"
pantry-manager add garlic 5 cloves

# View all pantry items
pantry-manager list

# Remove items from pantry
pantry-manager remove "red onion"
```

### Recipe Management

```bash
# List all imported recipes
pantry-manager recipes

# View recipe details
pantry-manager recipe 1

# Import a recipe from URL
pantry-manager import https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce

# Search recipes by title
pantry-manager search chicken
pantry-manager search pasta

# Mark a recipe as favorite
pantry-manager favorite 1 5 "Amazing dish!"
pantry-manager favorite 2 4
```

### Meal Planning

```bash
# Generate a meal plan for N meals
pantry-manager plan 5

# This will analyze your pantry and recipes to suggest meals
# that maximize ingredient reuse
```

## Database

All data is stored in a SQLite database at:
```
~/.local/share/pantry-manager/pantry.db
```

The database includes:
- Pantry inventory
- Imported recipes with ingredients
- Favorites with ratings
- Full-text search index for recipes

## Recipe Import

### Supported Sites

- NYT Cooking (cooking.nytimes.com)
- Any site using Schema.org Recipe markup

### Legal Notice

Recipe imports from NYT Cooking are for **personal, non-commercial use only**:
- NYT's Terms of Service prohibit automated scraping without permission
- Use at your own discretion for personal meal planning
- Do NOT use to build commercial recipe databases
- Do NOT distribute imported recipe data
- Rate limited to one recipe at a time with 2-second delays

### Example

```bash
pantry-manager import https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce
```

Output:
```
Importing recipe from https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce...
(2-second rate limit for respectful access)
⚠️  Personal use only - do not distribute recipe data

✅ Successfully imported: Classic Marinara Sauce
   Recipe ID: 1
   Ingredients: 6
   Parser: NYTParser
```

## Commands Reference

### add
Add or update ingredient(s) in your pantry.

**Natural language mode** (requires ANTHROPIC_API_KEY):
```bash
pantry-manager add "<natural language description>"
```

Examples:
- `pantry-manager add "four roma tomatoes and a bag of kale"`
- `pantry-manager add "2 cans of crushed tomatoes"`
- `pantry-manager add "three red onions, 5 cloves of garlic, and a bunch of spinach"`

The system will parse your input, show you what it understood, and ask for confirmation before adding items.

**Structured mode** (always available):
```bash
pantry-manager add <ingredient> <quantity> <unit> [notes]
```

Examples:
- `pantry-manager add "red onion" 2 whole`
- `pantry-manager add spinach 1 bag "organic"`

### list
Show all items currently in your pantry.

```bash
pantry-manager list
```

### remove
Remove an ingredient from your pantry.

```bash
pantry-manager remove <ingredient>
```

Example:
- `pantry-manager remove "red onion"`

### recipes
List all imported recipes.

```bash
pantry-manager recipes
```

### recipe
Show details for a specific recipe.

```bash
pantry-manager recipe <id>
```

Example:
- `pantry-manager recipe 1`

### import
Import a recipe from a URL.

```bash
pantry-manager import <url>
```

Example:
- `pantry-manager import https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce`

### search
Search local recipes by title.

```bash
pantry-manager search <query>
```

Example:
- `pantry-manager search chicken`

### plan
Generate a meal plan for N meals optimizing ingredient reuse.

```bash
pantry-manager plan <N>
```

Example:
- `pantry-manager plan 5`

### favorite
Mark a recipe as favorite with optional rating (1-5) and notes.

```bash
pantry-manager favorite <recipe_id> [rating] [notes]
```

Examples:
- `pantry-manager favorite 1 5 "Best pasta ever!"`
- `pantry-manager favorite 2 4`

### help
Show usage information.

```bash
pantry-manager help
```

## Development

### Project Structure

```
.
├── bin/
│   └── pantry-manager          # Main executable
├── lib/
│   ├── cli.rb                  # Formatting utilities
│   ├── database.rb             # Database setup and schema
│   ├── models.rb               # Recipe, Ingredient, PantryItem models
│   ├── recipe_importer.rb      # Recipe import orchestrator
│   ├── recipe_search.rb        # Local recipe search
│   ├── meal_planner.rb         # Meal planning logic
│   ├── ingredient_parser.rb    # Parse ingredient strings
│   ├── parsers/
│   │   ├── nyt_parser.rb       # NYT Cooking parser
│   │   └── schema_org_parser.rb # Schema.org parser
│   └── ...
├── SKILL.md                    # Claude Code skill configuration
└── README.md                   # This file
```

### Running Tests

```bash
# Phase 1: Basic pantry management
ruby test_phase1.rb

# Phase 2: Recipe import
ruby test_phase2.rb

# Phase 3: Search
ruby test_phase3.rb

# Phase 4: Meal planning
ruby test_phase4.rb
```

## Claude Code Integration

This tool is also available as a Claude Code skill. When using Claude Code, you can invoke commands like:

```
/pantry add spinach 1 bag
/pantry list
/pantry import https://cooking.nytimes.com/recipes/...
```

See SKILL.md for details on the Claude Code integration.

## Troubleshooting

### Command not found

Make sure the script is executable:
```bash
chmod +x /Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager
```

### Database errors

The database is created automatically on first run. If you encounter issues, you can delete and recreate it:

```bash
rm ~/.local/share/pantry-manager/pantry.db
pantry-manager list  # Will recreate the database
```

### Import failures

If recipe import fails:
1. Check that the URL is from a supported site
2. Ensure you have internet connectivity
3. Try again after a few seconds (rate limiting)
4. Check for site changes (parsers may need updates)

## License

Personal use only. See legal notices above regarding recipe imports.
