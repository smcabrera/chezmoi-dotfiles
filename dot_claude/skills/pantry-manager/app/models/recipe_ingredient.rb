module PantryManager
  class RecipeIngredient < ActiveRecord::Base
    self.table_name = 'recipe_ingredients'

    belongs_to :recipe, class_name: 'PantryManager::Recipe'
    belongs_to :ingredient, class_name: 'PantryManager::Ingredient'

    validates :recipe, presence: true
    validates :ingredient, presence: true, uniqueness: { scope: :recipe_id }
  end
end
