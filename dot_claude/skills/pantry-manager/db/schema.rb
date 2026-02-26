# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_17_000000) do
  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "last_cooked"
    t.text "notes"
    t.integer "rating"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_favorites_on_recipe_id", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "pantry_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "ingredient_id", null: false
    t.text "notes"
    t.string "quantity"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_pantry_items_on_ingredient_id", unique: true
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "ingredient_id", null: false
    t.text "original_text"
    t.string "quantity"
    t.integer "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "raw_data"
    t.string "source_url", null: false
    t.string "title", null: false
    t.string "total_time"
    t.datetime "updated_at", null: false
    t.string "yield_text"
    t.index ["source_url"], name: "index_recipes_on_source_url", unique: true
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.string "added_by", default: "user"
    t.datetime "created_at", null: false
    t.integer "ingredient_id", null: false
    t.text "notes"
    t.string "quantity"
    t.integer "recipe_id"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_shopping_list_items_on_ingredient_id", unique: true
  end

  add_foreign_key "favorites", "recipes", on_delete: :cascade
  add_foreign_key "pantry_items", "ingredients"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes", on_delete: :cascade
  add_foreign_key "shopping_list_items", "ingredients"
  add_foreign_key "shopping_list_items", "recipes"

end
