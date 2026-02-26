require 'spec_helper'

RSpec.describe PantryManager::CLI do
  describe '.format_pantry_list' do
    it 'returns "Pantry is empty." when items array is empty' do
      expect(described_class.format_pantry_list([])).to eq("Pantry is empty.")
    end

    it 'formats pantry items with quantity and unit' do
      item = double(
        ingredient_name: 'red onion',
        quantity: '1',
        unit: 'whole',
        notes: nil
      )

      output = described_class.format_pantry_list([item])
      expect(output).to include('**Current Pantry:**')
      expect(output).to include('red onion: 1 whole')
    end

    it 'includes notes when present' do
      item = double(
        ingredient_name: 'milk',
        quantity: '1',
        unit: 'gallon',
        notes: 'whole milk'
      )

      output = described_class.format_pantry_list([item])
      expect(output).to include('milk: 1 gallon (whole milk)')
    end

    it 'handles items with no unit' do
      item = double(
        ingredient_name: 'garlic',
        quantity: '3',
        unit: nil,
        notes: nil
      )

      output = described_class.format_pantry_list([item])
      expect(output).to include('garlic: 3')
    end
  end

  describe '.format_recipe_list' do
    it 'returns "No recipes found." when recipes array is empty' do
      expect(described_class.format_recipe_list([])).to eq("No recipes found.")
    end

    it 'formats recipe list with title, time, yield, and source' do
      recipe = double(
        id: 1,
        title: 'Classic Marinara Sauce',
        total_time: '30 minutes',
        yield_text: '4 servings',
        source_url: 'https://example.com/recipe'
      )

      output = described_class.format_recipe_list([recipe])
      expect(output).to include('**Imported Recipes:**')
      expect(output).to include('1. **Classic Marinara Sauce**')
      expect(output).to include('Time: 30 minutes')
      expect(output).to include('Yield: 4 servings')
      expect(output).to include('Source: https://example.com/recipe')
    end

    it 'handles missing time and yield gracefully' do
      recipe = double(
        id: 1,
        title: 'Test Recipe',
        total_time: nil,
        yield_text: nil,
        source_url: 'https://example.com/recipe'
      )

      output = described_class.format_recipe_list([recipe])
      expect(output).to include('Time: N/A')
      expect(output).to include('Yield: N/A')
    end
  end

  describe '.format_recipe_details' do
    let(:recipe) do
      recipe = create(:recipe,
        title: 'Classic Marinara Sauce',
        yield_text: '4 servings',
        total_time: '30 minutes',
        source_url: 'https://example.com/recipe'
      )

      garlic = create(:ingredient, name: 'garlic')
      tomato = create(:ingredient, name: 'tomato')

      create(:recipe_ingredient, recipe: recipe, ingredient: garlic, quantity: '3', unit: 'cloves')
      create(:recipe_ingredient, recipe: recipe, ingredient: tomato, quantity: '1', unit: 'can')

      recipe
    end

    it 'formats recipe details with title and metadata' do
      output = described_class.format_recipe_details(recipe)
      expect(output).to include('**Classic Marinara Sauce**')
      expect(output).to include('**Yield:** 4 servings')
      expect(output).to include('**Time:** 30 minutes')
      expect(output).to include('**Source:** https://example.com/recipe')
    end

    it 'formats ingredients list' do
      output = described_class.format_recipe_details(recipe)
      expect(output).to include('**Ingredients:**')
      expect(output).to include('- 3 cloves garlic')
      expect(output).to include('- 1 can tomato')
    end

    it 'handles missing quantity or unit' do
      recipe_with_partial = create(:recipe,
        title: 'Test Recipe',
        total_time: nil,
        yield_text: nil,
        source_url: 'https://example.com/recipe'
      )

      salt = create(:ingredient, name: 'salt')
      create(:recipe_ingredient, :no_quantity, recipe: recipe_with_partial, ingredient: salt)

      output = described_class.format_recipe_details(recipe_with_partial)
      expect(output).to include('-  salt')
    end
  end
end
