class AddShoppingListItems < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :ingredient, null: false, foreign_key: true, index: { unique: true }
      t.string :quantity
      t.string :unit
      t.text :notes
      t.string :added_by, default: 'user'
      t.integer :recipe_id
      t.timestamps
    end

    add_foreign_key :shopping_list_items, :recipes, column: :recipe_id
  end
end
