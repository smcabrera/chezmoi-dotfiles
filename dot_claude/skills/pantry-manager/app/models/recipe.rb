module PantryManager
  class Recipe < ActiveRecord::Base
    self.table_name = 'recipes'

    has_many :recipe_ingredients, dependent: :destroy, class_name: 'PantryManager::RecipeIngredient'
    has_many :ingredients, through: :recipe_ingredients, class_name: 'PantryManager::Ingredient'
    has_one :favorite, dependent: :destroy, class_name: 'PantryManager::Favorite'

    validates :source_url, presence: true, uniqueness: true
    validates :title, presence: true

    after_create :index_in_fts
    after_update :index_in_fts
    after_destroy :remove_from_fts

    # Full-text search method
    def self.search_by_title(query, limit: 10)
      return none if query.blank?
      
      # Sanitize limit to ensure it's an integer
      safe_limit = limit.to_i.clamp(1, 100)
      
      sql = <<-SQL
        SELECT r.* 
        FROM recipes r
        JOIN recipes_fts fts ON r.id = fts.rowid
        WHERE fts.title MATCH ?
        LIMIT #{safe_limit}
      SQL
      
      find_by_sql([sql, query])
    end

    private

    def index_in_fts
      self.class.connection.execute(
        "INSERT OR REPLACE INTO recipes_fts(rowid, title) VALUES (?, ?)",
        [id, title]
      )
    end

    def remove_from_fts
      self.class.connection.execute(
        "DELETE FROM recipes_fts WHERE rowid = ?", [id]
      )
    end

    public

    # Search by ingredients
    def self.search_by_ingredients(ingredient_names, limit: 10)
      return none if ingredient_names.empty?
      
      joins(:ingredients)
        .where(ingredients: { name: ingredient_names })
        .select('recipes.*, COUNT(DISTINCT ingredients.id) as match_count')
        .group('recipes.id')
        .order('match_count DESC')
        .limit(limit)
    end
  end
end
