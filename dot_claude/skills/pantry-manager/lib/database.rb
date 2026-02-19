require 'sqlite3'
require 'fileutils'

module PantryManager
  class Database
    DB_PATH = File.expand_path('~/.local/share/pantry-manager/pantry.db')

    SCHEMA = <<~SQL
      -- Recipes table
      CREATE TABLE IF NOT EXISTS recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_url TEXT UNIQUE,
        title TEXT NOT NULL,
        yield_text TEXT,
        total_time TEXT,
        raw_data TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      -- Ingredients table (normalized, many-to-many with recipes)
      CREATE TABLE IF NOT EXISTS ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );

      -- Recipe ingredients join table
      CREATE TABLE IF NOT EXISTS recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        ingredient_id INTEGER NOT NULL,
        quantity TEXT,
        unit TEXT,
        original_text TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
      );

      -- Pantry table
      CREATE TABLE IF NOT EXISTS pantry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ingredient_id INTEGER NOT NULL,
        quantity TEXT,
        unit TEXT,
        notes TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
      );

      -- Favorites table (track liked recipes)
      CREATE TABLE IF NOT EXISTS favorites (
        recipe_id INTEGER PRIMARY KEY,
        rating INTEGER CHECK (rating >= 1 AND rating <= 5),
        notes TEXT,
        last_cooked DATE,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      );

      -- Full-text search index for recipe titles
      CREATE VIRTUAL TABLE IF NOT EXISTS recipes_fts USING fts5(
        title,
        content='recipes',
        content_rowid='id'
      );

      -- Triggers to keep FTS index in sync
      CREATE TRIGGER IF NOT EXISTS recipes_fts_insert AFTER INSERT ON recipes BEGIN
        INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
      END;

      CREATE TRIGGER IF NOT EXISTS recipes_fts_delete AFTER DELETE ON recipes BEGIN
        DELETE FROM recipes_fts WHERE rowid = old.id;
      END;

      CREATE TRIGGER IF NOT EXISTS recipes_fts_update AFTER UPDATE ON recipes BEGIN
        DELETE FROM recipes_fts WHERE rowid = old.id;
        INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
      END;
    SQL

    def self.setup
      FileUtils.mkdir_p(File.dirname(DB_PATH))
      db = SQLite3::Database.new(DB_PATH)
      db.results_as_hash = true

      # Create tables
      db.execute_batch(SCHEMA)

      db
    end

    def self.connection
      @connection ||= setup
    end
  end
end
