# Project Guidelines for AI Agents

## Code Style

### Prefer Plain Objects and Modules Over Service Objects

Avoid introducing service object classes (e.g., `RecipeImportService`, `ShoppingListManager`) unless there is a clear reason for them. Instead:

- Add class methods directly to the relevant ActiveRecord model (e.g., `PantryItem.add_or_update`)
- Use plain Ruby modules with class methods for stateless operations (e.g., `ShoppingList.buy`)
- Reserve classes for things that genuinely have state or lifecycle

Service objects are not forbidden, but reach for them only when a model or module method would be awkward — for example, when orchestrating across many models or when the operation has complex branching that doesn't belong on any single model.
