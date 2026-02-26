require 'spec_helper'

RSpec.describe PantryManager::ShoppingListItem do
  describe '.add_or_update' do
    it 'adds a new item to the shopping list' do
      expect {
        described_class.add_or_update('lemon', '2', 'whole')
      }.to change { described_class.count }.by(1)
    end

    it 'normalizes ingredient names to lowercase and stripped' do
      described_class.add_or_update('  Fresh Dill  ', '1', 'bunch')
      expect(described_class.first.ingredient_name).to eq('fresh dill')
    end

    it 'updates existing item if ingredient already on shopping list' do
      described_class.add_or_update('tahini', '1', 'jar')
      described_class.add_or_update('tahini', '2', 'jars')

      items = described_class.joins(:ingredient).where(ingredients: { name: 'tahini' })
      expect(items.length).to eq(1)
      expect(items.first.quantity).to eq('2')
      expect(items.first.unit).to eq('jars')
    end

    it 'stores optional notes' do
      described_class.add_or_update('cannellini beans', '1', 'can', notes: 'organic if possible')
      expect(described_class.first.notes).to eq('organic if possible')
    end

    it 'stores added_by source' do
      described_class.add_or_update('dill', '1', 'bunch', added_by: 'recipe')
      expect(described_class.first.added_by).to eq('recipe')
    end

    it 'defaults added_by to user' do
      described_class.add_or_update('lemon', '1', 'whole')
      expect(described_class.first.added_by).to eq('user')
    end

    it 'stores optional recipe_id' do
      recipe = create(:recipe, title: 'Test Recipe', source_url: 'http://example.com')
      described_class.add_or_update('tahini', '1', 'jar', recipe_id: recipe.id)
      expect(described_class.first.recipe_id).to eq(recipe.id)
    end
  end

  describe '.remove_by_name' do
    it 'removes an item from the shopping list' do
      described_class.add_or_update('lemon', '2', 'whole')
      expect {
        described_class.remove_by_name('lemon')
      }.to change { described_class.count }.by(-1)
    end

    it 'returns true when item is removed' do
      described_class.add_or_update('dill', '1', 'bunch')
      expect(described_class.remove_by_name('dill')).to be true
    end

    it 'returns false when item does not exist' do
      expect(described_class.remove_by_name('nonexistent')).to be false
    end

    it 'is case-insensitive' do
      described_class.add_or_update('tahini', '1', 'jar')
      expect(described_class.remove_by_name('TAHINI')).to be true
    end
  end

  describe '.move_to_pantry' do
    it 'removes the item from the shopping list' do
      described_class.add_or_update('lemon', '2', 'whole')
      expect {
        described_class.move_to_pantry('lemon')
      }.to change { described_class.count }.by(-1)
    end

    it 'adds the item to the pantry' do
      described_class.add_or_update('lemon', '2', 'whole')
      expect {
        described_class.move_to_pantry('lemon')
      }.to change { PantryManager::PantryItem.count }.by(1)
    end

    it 'carries quantity and unit to the pantry' do
      described_class.add_or_update('tahini', '1', 'jar')
      described_class.move_to_pantry('tahini')

      pantry_item = PantryManager::PantryItem.joins(:ingredient)
        .where(ingredients: { name: 'tahini' }).first
      expect(pantry_item.quantity).to eq('1')
      expect(pantry_item.unit).to eq('jar')
    end

    it 'allows overriding quantity and unit when moving to pantry' do
      described_class.add_or_update('tahini', '1', 'jar')
      described_class.move_to_pantry('tahini', quantity: '2', unit: 'jars')

      pantry_item = PantryManager::PantryItem.joins(:ingredient)
        .where(ingredients: { name: 'tahini' }).first
      expect(pantry_item.quantity).to eq('2')
      expect(pantry_item.unit).to eq('jars')
    end

    it 'returns false when item is not on shopping list' do
      expect(described_class.move_to_pantry('nonexistent')).to be false
    end
  end

  describe '#ingredient_name' do
    it 'returns the name of the associated ingredient' do
      described_class.add_or_update('cannellini beans', '1', 'can')
      expect(described_class.first.ingredient_name).to eq('cannellini beans')
    end
  end

  describe '.all' do
    it 'returns all shopping list items' do
      described_class.add_or_update('lemon', '2', 'whole')
      described_class.add_or_update('dill', '1', 'bunch')
      expect(described_class.count).to eq(2)
    end
  end
end
