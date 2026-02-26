module PantryManager
  class Ingredient < ActiveRecord::Base
    self.table_name = 'ingredients'

    has_many :recipe_ingredients, dependent: :destroy, class_name: 'PantryManager::RecipeIngredient'
    has_many :recipes, through: :recipe_ingredients, class_name: 'PantryManager::Recipe'
    has_one :pantry_item, dependent: :destroy, class_name: 'PantryManager::PantryItem'
    has_one :shopping_list_item, dependent: :destroy, class_name: 'PantryManager::ShoppingListItem'

    validates :name, presence: true, uniqueness: true

    before_validation :normalize_name

    private

    def normalize_name
      self.name = name.to_s.downcase.strip
    end
  end
end
