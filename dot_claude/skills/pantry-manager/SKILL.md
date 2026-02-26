---
name: pantry-manager
description: Manage pantry inventory and plan meals with maximum ingredient reuse. Use when managing ingredients, searching recipes, or planning meals.
argument-hint: "[command] [arguments]"
allowed-tools: Bash
---

# Pantry Manager

Your personal meal planning assistant. I help you manage your pantry inventory, import recipes, and plan meals that maximize ingredient reuse.

## Quick Start

When you invoke this skill, I'll help you:
- **Add ingredients** to your pantry with quantities and units
- **View your pantry** to see what you have on hand
- **Search recipes** from your imported collection
- **Plan meals** that efficiently reuse ingredients
- **Import recipes** from NYT Cooking, Budget Bytes, and other sites

## How It Works

This skill uses the `pantry-manager` CLI tool located at:
```
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager
```

All commands are executed through this CLI, which maintains your pantry database at:
```
~/.local/share/pantry-manager/pantry.db
```

## Available Commands

### Pantry Management
- `add <ingredient> <quantity> <unit> [notes]` - Add ingredient to pantry
- `list` - Show current pantry state
- `remove <ingredient>` - Remove ingredient from pantry

### Recipe Management
- `recipes` - List all imported recipes
- `recipe <id>` - Show detailed recipe information
- `import <url>` - Import recipe from URL (NYT Cooking, Budget Bytes, etc.)
- `search <query>` - Search recipes by title or ingredients
- `favorite <recipe_id> [rating] [notes]` - Mark recipe as favorite

### Meal Planning
- `plan <N>` - Generate N-meal plan optimizing ingredient reuse
- `help` - Show all available commands

For detailed command documentation, see [COMMANDS.md](COMMANDS.md).

## Implementation

When handling user requests, I will:

1. **Parse the command** - Extract the command and arguments from the user's request
2. **Execute via CLI** - Run the appropriate `bin/pantry-manager` command using the Bash tool
3. **Format the output** - Present results in a friendly, conversational way
4. **Suggest next steps** - Help the user understand what they can do next

### Example Implementations

**Adding ingredients:**
```bash
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager add "red onion" 2 whole
```

**Listing pantry:**
```bash
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager list
```

**Searching recipes:**
```bash
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager search chicken
```

**Planning meals:**
```bash
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager plan 3
```

**Importing recipes:**
```bash
/Users/stephen/.claude/skills/pantry-manager/bin/pantry-manager import "https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce"
```

## Response Style

Be conversational and helpful:
- When showing pantry items, suggest what the user could make
- When importing recipes, remind about personal use only
- When planning meals, emphasize ingredient reuse and explain why recipes work well together
- Show shopping lists clearly (what to buy vs what they have)

## Legal Notice

**NYT Cooking Import**: For personal, non-commercial use only. See [LICENSE.md](LICENSE.md) for complete terms.

**Rate Limiting**: Recipe imports are limited to one at a time with a 2-second delay to be respectful of servers.
