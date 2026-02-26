module PantryManager
  class ShoppingListItem < ActiveRecord::Base
    self.table_name = 'shopping_list_items'

    belongs_to :ingredient, class_name: 'PantryManager::Ingredient'
    belongs_to :recipe, class_name: 'PantryManager::Recipe', optional: true

    validates :ingredient, presence: true, uniqueness: true

    def ingredient_name
      ingredient&.name
    end

    def self.add_or_update(ingredient_name, quantity, unit, notes: nil, added_by: 'user', recipe_id: nil)
      ingredient = Ingredient.find_or_create_by!(name: ingredient_name.downcase.strip)

      item = find_or_initialize_by(ingredient: ingredient)
      item.quantity = quantity
      item.unit = unit
      item.notes = notes
      item.added_by = added_by
      item.recipe_id = recipe_id
      item.save!

      item
    end

    def self.remove_by_name(ingredient_name)
      ingredient = Ingredient.find_by(name: ingredient_name.downcase.strip)
      return false unless ingredient

      item = find_by(ingredient: ingredient)
      return false unless item

      item.destroy
      true
    end

    def self.move_to_pantry(ingredient_name, quantity: nil, unit: nil)
      ingredient = Ingredient.find_by(name: ingredient_name.downcase.strip)
      return false unless ingredient

      item = find_by(ingredient: ingredient)
      return false unless item

      PantryItem.add_or_update(
        ingredient_name,
        quantity || item.quantity,
        unit || item.unit
      )
      item.destroy
      true
    end
  end
end
