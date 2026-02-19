module PantryManager
  class Recipe
    attr_accessor :id, :source_url, :title, :yield_text, :total_time, :raw_data, :created_at

    def self.find(id)
      db = Database.connection
      row = db.execute("SELECT * FROM recipes WHERE id = ?", [id]).first
      return nil unless row
      from_hash(row)
    end

    def self.all
      db = Database.connection
      rows = db.execute("SELECT * FROM recipes ORDER BY created_at DESC")
      rows.map { |row| from_hash(row) }
    end

    def self.from_hash(hash)
      recipe = new
      recipe.id = hash['id']
      recipe.source_url = hash['source_url']
      recipe.title = hash['title']
      recipe.yield_text = hash['yield_text']
      recipe.total_time = hash['total_time']
      recipe.raw_data = hash['raw_data']
      recipe.created_at = hash['created_at']
      recipe
    end

    def ingredients
      db = Database.connection
      rows = db.execute(
        "SELECT i.name, ri.quantity, ri.unit, ri.original_text
         FROM recipe_ingredients ri
         JOIN ingredients i ON ri.ingredient_id = i.id
         WHERE ri.recipe_id = ?
         ORDER BY ri.id",
        [id]
      )
      rows
    end
  end

  class Ingredient
    attr_accessor :id, :name

    def self.find_by_name(name)
      db = Database.connection
      row = db.execute("SELECT * FROM ingredients WHERE name = ?", [name]).first
      return nil unless row
      from_hash(row)
    end

    def self.find_or_create(name)
      existing = find_by_name(name)
      return existing if existing

      db = Database.connection
      db.execute("INSERT INTO ingredients (name) VALUES (?)", [name])
      find_by_name(name)
    end

    def self.from_hash(hash)
      ingredient = new
      ingredient.id = hash['id']
      ingredient.name = hash['name']
      ingredient
    end
  end

  class PantryItem
    attr_accessor :id, :ingredient_id, :ingredient_name, :quantity, :unit, :notes, :updated_at

    def self.all
      db = Database.connection
      rows = db.execute(
        "SELECT p.*, i.name as ingredient_name
         FROM pantry p
         JOIN ingredients i ON p.ingredient_id = i.id
         ORDER BY i.name"
      )
      rows.map { |row| from_hash(row) }
    end

    def self.add(ingredient_name, quantity, unit, notes = nil)
      db = Database.connection
      ingredient = Ingredient.find_or_create(ingredient_name.downcase.strip)

      # Check if item already exists in pantry
      existing = db.execute(
        "SELECT id FROM pantry WHERE ingredient_id = ?",
        [ingredient.id]
      ).first

      if existing
        # Update existing
        db.execute(
          "UPDATE pantry SET quantity = ?, unit = ?, notes = ?, updated_at = CURRENT_TIMESTAMP
           WHERE id = ?",
          [quantity, unit, notes, existing['id']]
        )
      else
        # Insert new
        db.execute(
          "INSERT INTO pantry (ingredient_id, quantity, unit, notes) VALUES (?, ?, ?, ?)",
          [ingredient.id, quantity, unit, notes]
        )
      end
    end

    def self.remove(ingredient_name)
      db = Database.connection
      ingredient = Ingredient.find_by_name(ingredient_name.downcase.strip)
      return false unless ingredient

      db.execute("DELETE FROM pantry WHERE ingredient_id = ?", [ingredient.id])
      true
    end

    def self.from_hash(hash)
      item = new
      item.id = hash['id']
      item.ingredient_id = hash['ingredient_id']
      item.ingredient_name = hash['ingredient_name']
      item.quantity = hash['quantity']
      item.unit = hash['unit']
      item.notes = hash['notes']
      item.updated_at = hash['updated_at']
      item
    end
  end
end
