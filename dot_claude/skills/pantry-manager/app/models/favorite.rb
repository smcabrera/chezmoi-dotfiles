module PantryManager
  class Favorite < ActiveRecord::Base
    self.table_name = 'favorites'

    belongs_to :recipe, class_name: 'PantryManager::Recipe'

    validates :recipe, presence: true, uniqueness: true
    validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  end
end
