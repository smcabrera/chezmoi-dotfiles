# Load all models
Dir[File.expand_path('../app/models/*.rb', __dir__)].sort.each { |f| require f }

# Load all lib files
require_relative 'ingredient_parser'
require_relative 'recipe_importer'
require_relative 'recipe_search'
require_relative 'meal_planner'
require_relative 'shopping_list'
require_relative 'spoonacular_client'
require_relative 'search_orchestrator'

# Load parsers
require_relative 'parsers/nyt_parser'
require_relative 'parsers/schema_org_parser'
