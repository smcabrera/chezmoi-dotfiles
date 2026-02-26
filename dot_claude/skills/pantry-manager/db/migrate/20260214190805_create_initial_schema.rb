class CreateInitialSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :source_url, null: false, index: { unique: true }
      t.string :title, null: false
      t.string :yield_text
      t.string :total_time
      t.text :raw_data
      t.timestamps
    end

    create_table :ingredients do |t|
      t.string :name, null: false, index: { unique: true }
      t.timestamps
    end

    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }
      t.references :ingredient, null: false, foreign_key: true
      t.string :quantity
      t.string :unit
      t.text :original_text
      t.timestamps
    end

    create_table :pantry_items do |t|
      t.references :ingredient, null: false, foreign_key: true, index: { unique: true }
      t.string :quantity
      t.string :unit
      t.text :notes
      t.timestamps
    end

    create_table :favorites do |t|
      t.references :recipe, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.integer :rating
      t.text :notes
      t.date :last_cooked
      t.timestamps
    end

    # Full-text search will be handled by SQLite FTS separately
    # We'll add a custom SQL migration for that
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE VIRTUAL TABLE recipes_fts USING fts5(
            title,
            content='recipes',
            content_rowid='id'
          );

          CREATE TRIGGER recipes_fts_insert AFTER INSERT ON recipes BEGIN
            INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
          END;

          CREATE TRIGGER recipes_fts_delete AFTER DELETE ON recipes BEGIN
            DELETE FROM recipes_fts WHERE rowid = old.id;
          END;

          CREATE TRIGGER recipes_fts_update AFTER UPDATE ON recipes BEGIN
            DELETE FROM recipes_fts WHERE rowid = old.id;
            INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
          END;
        SQL
      end

      dir.down do
        execute "DROP TRIGGER IF EXISTS recipes_fts_update"
        execute "DROP TRIGGER IF EXISTS recipes_fts_delete"
        execute "DROP TRIGGER IF EXISTS recipes_fts_insert"
        execute "DROP TABLE IF EXISTS recipes_fts"
      end
    end
  end
end
