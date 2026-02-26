module PantryManager
  class PantryItem < ActiveRecord::Base
    self.table_name = 'pantry_items'

    belongs_to :ingredient, class_name: 'PantryManager::Ingredient'

    validates :ingredient, presence: true, uniqueness: true

    def ingredient_name
      ingredient&.name
    end

    def self.add_or_update(ingredient_name, quantity, unit, notes = nil)
      ingredient = Ingredient.find_or_create_by!(name: ingredient_name.downcase.strip)
      
      pantry_item = find_or_initialize_by(ingredient: ingredient)
      pantry_item.quantity = quantity
      pantry_item.unit = unit
      pantry_item.notes = notes
      pantry_item.save!
      
      pantry_item
    end

    def self.remove_by_name(ingredient_name)
      ingredient = Ingredient.find_by(name: ingredient_name.downcase.strip)
      return false unless ingredient

      pantry_item = find_by(ingredient: ingredient)
      return false unless pantry_item
      
      pantry_item.destroy
      true
    end
  end
end
