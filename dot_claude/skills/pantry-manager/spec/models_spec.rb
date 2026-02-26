require 'spec_helper'

RSpec.describe PantryManager::Recipe do
  describe '.find' do
    it 'returns nil when recipe does not exist' do
      expect(described_class.find_by(id: 999)).to be_nil
    end

    it 'returns a recipe when it exists' do
      recipe = create(:recipe,
        title: 'Test Recipe',
        source_url: 'http://example.com/recipe'
      )

      found = described_class.find(recipe.id)
      expect(found).not_to be_nil
      expect(found.title).to eq('Test Recipe')
      expect(found.source_url).to eq('http://example.com/recipe')
    end
  end

  describe '.all' do
    it 'returns an empty array when no recipes exist' do
      expect(described_class.all.to_a).to eq([])
    end

    it 'returns all recipes ordered by created_at DESC' do
      recipe1 = create(:recipe, title: 'Recipe 1', source_url: 'http://example.com/1')
      sleep 0.01 # Ensure different timestamps
      recipe2 = create(:recipe, title: 'Recipe 2', source_url: 'http://example.com/2')

      recipes = described_class.order(created_at: :desc).to_a
      expect(recipes.length).to eq(2)
      expect(recipes.first.title).to eq('Recipe 2')
      expect(recipes.last.title).to eq('Recipe 1')
    end
  end

  describe '#ingredients' do
    it 'returns recipe ingredients with quantities and units' do
      recipe = create(:recipe, title: 'Test Recipe', source_url: 'http://example.com')
      ingredient = create(:ingredient, name: 'garlic')

      create(:recipe_ingredient,
        recipe: recipe,
        ingredient: ingredient,
        quantity: '3',
        unit: 'cloves',
        original_text: '3 cloves garlic, minced'
      )

      ingredients = recipe.recipe_ingredients.includes(:ingredient)

      expect(ingredients.length).to eq(1)
      expect(ingredients.first.ingredient.name).to eq('garlic')
      expect(ingredients.first.quantity).to eq('3')
      expect(ingredients.first.unit).to eq('cloves')
    end
  end
end

RSpec.describe PantryManager::Ingredient do
  describe '.find_by' do
    it 'returns nil when ingredient does not exist' do
      expect(described_class.find_by(name: 'nonexistent')).to be_nil
    end

    it 'returns an ingredient when it exists' do
      create(:ingredient, name: 'garlic')

      ingredient = described_class.find_by(name: 'garlic')
      expect(ingredient).not_to be_nil
      expect(ingredient.name).to eq('garlic')
    end
  end

  describe '.find_or_create_by!' do
    it 'creates a new ingredient if it does not exist' do
      expect {
        described_class.find_or_create_by!(name: 'onion')
      }.to change { described_class.count }.by(1)
    end

    it 'returns existing ingredient if it already exists' do
      create(:ingredient, name: 'garlic')

      expect {
        described_class.find_or_create_by!(name: 'garlic')
      }.not_to change { described_class.count }
    end

    it 'returns the ingredient object' do
      ingredient = described_class.find_or_create_by!(name: 'tomato')
      expect(ingredient).not_to be_nil
      expect(ingredient.name).to eq('tomato')
    end
  end

  describe 'normalization' do
    it 'normalizes names to lowercase and stripped' do
      ingredient = create(:ingredient, name: '  Red Onion  ')
      expect(ingredient.name).to eq('red onion')
    end
  end
end

RSpec.describe PantryManager::PantryItem do
  describe '.add_or_update' do
    it 'adds a new item to the pantry' do
      expect {
        described_class.add_or_update('red onion', '1', 'whole')
      }.to change { described_class.count }.by(1)
    end

    it 'normalizes ingredient names to lowercase and stripped' do
      described_class.add_or_update('  Red Onion  ', '1', 'whole')
      items = described_class.all
      expect(items.first.ingredient_name).to eq('red onion')
    end

    it 'updates existing item if ingredient already in pantry' do
      described_class.add_or_update('garlic', '1', 'clove')
      described_class.add_or_update('garlic', '3', 'cloves')

      items = described_class.joins(:ingredient).where(ingredients: { name: 'garlic' })
      expect(items.length).to eq(1)
      expect(items.first.quantity).to eq('3')
      expect(items.first.unit).to eq('cloves')
    end

    it 'stores optional notes' do
      described_class.add_or_update('milk', '1', 'gallon', 'whole milk')
      items = described_class.all
      expect(items.first.notes).to eq('whole milk')
    end
  end

  describe '.remove_by_name' do
    it 'removes an item from the pantry' do
      described_class.add_or_update('garlic', '3', 'cloves')
      expect {
        described_class.remove_by_name('garlic')
      }.to change { described_class.count }.by(-1)
    end

    it 'returns true when item is removed' do
      described_class.add_or_update('onion', '1', 'whole')
      expect(described_class.remove_by_name('onion')).to be true
    end

    it 'returns false when item does not exist' do
      expect(described_class.remove_by_name('nonexistent')).to be false
    end

    it 'is case-insensitive' do
      described_class.add_or_update('garlic', '3', 'cloves')
      expect(described_class.remove_by_name('GARLIC')).to be true
    end
  end

  describe '.all' do
    it 'returns all pantry items' do
      described_class.add_or_update('garlic', '3', 'cloves')
      described_class.add_or_update('onion', '1', 'whole')

      items = described_class.all
      expect(items.length).to eq(2)
    end

    it 'includes ingredient names in results' do
      described_class.add_or_update('tomato', '5', 'whole')
      items = described_class.includes(:ingredient).all
      expect(items.first.ingredient_name).to eq('tomato')
    end

    it 'orders items by ingredient name' do
      described_class.add_or_update('zucchini', '2', 'whole')
      described_class.add_or_update('apple', '3', 'whole')

      items = described_class.joins(:ingredient).order('ingredients.name')
      expect(items.first.ingredient_name).to eq('apple')
      expect(items.last.ingredient_name).to eq('zucchini')
    end
  end
end
