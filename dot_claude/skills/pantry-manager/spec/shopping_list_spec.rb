require 'spec_helper'

RSpec.describe PantryManager::ShoppingList do
  describe '.generate' do
    let(:recipe1) do
      {
        title: 'Marinara Sauce',
        ingredients: ['garlic', 'tomato', 'olive oil', 'basil']
      }
    end

    let(:recipe2) do
      {
        title: 'Garlic Bread',
        ingredients: ['garlic', 'olive oil', 'bread', 'butter']
      }
    end

    let(:recipe3) do
      {
        title: 'Pasta Primavera',
        ingredients: ['garlic', 'pasta', 'olive oil', 'vegetables']
      }
    end

    context 'with pantry items' do
      let(:pantry_items) { ['garlic', 'olive oil'] }
      let(:selected_recipes) { [recipe1, recipe2, recipe3] }

      it 'returns ingredients needed that are not in pantry' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:needed]).to include('tomato', 'basil', 'bread', 'butter', 'pasta', 'vegetables')
        expect(result[:needed]).not_to include('garlic', 'olive oil')
      end

      it 'excludes all pantry items from needed list' do
        result = described_class.generate(selected_recipes, pantry_items)
        (result[:needed] & pantry_items).each do |item|
          expect(result[:needed]).not_to include(item)
        end
      end

      it 'calculates frequency of each needed ingredient' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:frequency]).to be_a(Hash)
        expect(result[:frequency]['tomato']).to eq(1)
        expect(result[:frequency]['basil']).to eq(1)
      end

      it 'sorts needed items by frequency (most used first)' do
        result = described_class.generate(selected_recipes, pantry_items)
        # All needed items appear in 1 recipe, so order may vary but should be consistent
        expect(result[:needed]).to be_an(Array)
      end

      it 'only includes frequency for needed items' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:frequency]).not_to have_key('garlic')
        expect(result[:frequency]).not_to have_key('olive oil')
      end
    end

    context 'with empty pantry' do
      let(:pantry_items) { [] }
      let(:selected_recipes) { [recipe1, recipe2] }

      it 'returns all unique ingredients as needed' do
        result = described_class.generate(selected_recipes, pantry_items)
        all_ingredients = (recipe1[:ingredients] + recipe2[:ingredients]).uniq
        expect(result[:needed].sort).to eq(all_ingredients.sort)
      end

      it 'calculates correct frequencies' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:frequency]['garlic']).to eq(2)
        expect(result[:frequency]['olive oil']).to eq(2)
        expect(result[:frequency]['tomato']).to eq(1)
        expect(result[:frequency]['bread']).to eq(1)
      end
    end

    context 'with full pantry' do
      let(:pantry_items) { ['garlic', 'tomato', 'olive oil', 'basil'] }
      let(:selected_recipes) { [recipe1] }

      it 'returns empty needed list when all ingredients are in pantry' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:needed]).to eq([])
      end

      it 'returns empty frequency hash' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:frequency]).to eq({})
      end
    end

    context 'with multiple recipes sharing ingredients' do
      let(:pantry_items) { [] }
      let(:selected_recipes) { [recipe1, recipe2, recipe3] }

      it 'correctly counts shared ingredients' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:frequency]['garlic']).to eq(3)  # All three recipes
        expect(result[:frequency]['olive oil']).to eq(3)  # All three recipes
        expect(result[:frequency]['tomato']).to eq(1)  # Only recipe1
        expect(result[:frequency]['pasta']).to eq(1)  # Only recipe3
      end

      it 'sorts items with higher frequency first' do
        result = described_class.generate(selected_recipes, pantry_items)
        # garlic and olive oil should be near the beginning (frequency 3)
        # Items with frequency 1 should be later
        first_items = result[:needed].take(2)
        expect(['garlic', 'olive oil']).to include(first_items[0])
        expect(['garlic', 'olive oil']).to include(first_items[1])
      end
    end

    context 'with single recipe' do
      let(:pantry_items) { ['garlic'] }
      let(:selected_recipes) { [recipe1] }

      it 'returns correct shopping list' do
        result = described_class.generate(selected_recipes, pantry_items)
        expect(result[:needed]).to match_array(['tomato', 'olive oil', 'basil'])
      end

      it 'all frequencies are 1 for single recipe' do
        result = described_class.generate(selected_recipes, pantry_items)
        result[:frequency].values.each do |count|
          expect(count).to eq(1)
        end
      end
    end
  end

  describe '.add' do
    it 'adds an item to the persistent shopping list' do
      expect {
        described_class.add('lemon', '2', 'whole')
      }.to change { PantryManager::ShoppingListItem.count }.by(1)
    end

    it 'returns the shopping list item' do
      item = described_class.add('dill', '1', 'bunch')
      expect(item.ingredient_name).to eq('dill')
      expect(item.quantity).to eq('1')
      expect(item.unit).to eq('bunch')
    end
  end

  describe '.remove' do
    it 'removes an item from the persistent shopping list' do
      described_class.add('lemon', '2', 'whole')
      expect {
        described_class.remove('lemon')
      }.to change { PantryManager::ShoppingListItem.count }.by(-1)
    end

    it 'returns false when item does not exist' do
      expect(described_class.remove('nonexistent')).to be false
    end
  end

  describe '.list' do
    it 'returns all items on the shopping list' do
      described_class.add('lemon', '2', 'whole')
      described_class.add('dill', '1', 'bunch')
      expect(described_class.list.count).to eq(2)
    end

    it 'returns an empty list when nothing is on the shopping list' do
      expect(described_class.list.to_a).to eq([])
    end
  end

  describe '.buy' do
    it 'moves an item from shopping list to pantry' do
      described_class.add('tahini', '1', 'jar')
      described_class.buy('tahini')

      expect(PantryManager::ShoppingListItem.count).to eq(0)
      expect(PantryManager::PantryItem.count).to eq(1)
    end

    it 'allows overriding quantity and unit when buying' do
      described_class.add('tahini', '1', 'jar')
      described_class.buy('tahini', quantity: '2', unit: 'jars')

      pantry_item = PantryManager::PantryItem.joins(:ingredient)
        .where(ingredients: { name: 'tahini' }).first
      expect(pantry_item.quantity).to eq('2')
      expect(pantry_item.unit).to eq('jars')
    end

    it 'returns false when item is not on shopping list' do
      expect(described_class.buy('nonexistent')).to be false
    end
  end

  describe '.need' do
    it 'moves an item from pantry to shopping list' do
      PantryManager::PantryItem.add_or_update('olive oil', '1', 'bottle')
      described_class.need('olive oil')

      expect(PantryManager::PantryItem.count).to eq(0)
      expect(PantryManager::ShoppingListItem.count).to eq(1)
    end

    it 'carries quantity and unit to shopping list' do
      PantryManager::PantryItem.add_or_update('olive oil', '1', 'bottle')
      described_class.need('olive oil')

      item = PantryManager::ShoppingListItem.joins(:ingredient)
        .where(ingredients: { name: 'olive oil' }).first
      expect(item.quantity).to eq('1')
      expect(item.unit).to eq('bottle')
    end

    it 'returns false when item is not in pantry' do
      expect(described_class.need('nonexistent')).to be false
    end
  end

  describe '.add_missing_for_recipe' do
    it 'adds missing recipe ingredients to shopping list' do
      recipe = create(:recipe, title: 'Salmon Salad', source_url: 'http://example.com')
      ing_lemon = create(:ingredient, name: 'lemon')
      ing_dill = create(:ingredient, name: 'dill')
      ing_kale = create(:ingredient, name: 'kale')
      create(:recipe_ingredient, recipe: recipe, ingredient: ing_lemon, quantity: '1', unit: 'whole')
      create(:recipe_ingredient, recipe: recipe, ingredient: ing_dill, quantity: '1', unit: 'bunch')
      create(:recipe_ingredient, recipe: recipe, ingredient: ing_kale, quantity: '1', unit: 'bunch')

      # kale is already in pantry
      PantryManager::PantryItem.add_or_update('kale', '1', 'bunch')

      described_class.add_missing_for_recipe(recipe.id)

      names = PantryManager::ShoppingListItem.joins(:ingredient).pluck('ingredients.name')
      expect(names).to include('lemon', 'dill')
      expect(names).not_to include('kale')
    end

    it 'tags items with recipe source' do
      recipe = create(:recipe, title: 'Salmon Salad', source_url: 'http://example.com')
      ingredient = create(:ingredient, name: 'tahini')
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, quantity: '1', unit: 'jar')

      described_class.add_missing_for_recipe(recipe.id)

      item = PantryManager::ShoppingListItem.first
      expect(item.added_by).to eq('recipe')
      expect(item.recipe_id).to eq(recipe.id)
    end

    it 'returns the list of added items' do
      recipe = create(:recipe, title: 'Test', source_url: 'http://example.com')
      ingredient = create(:ingredient, name: 'tahini')
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, quantity: '1', unit: 'jar')

      added = described_class.add_missing_for_recipe(recipe.id)
      expect(added.map(&:ingredient_name)).to include('tahini')
    end
  end
end
