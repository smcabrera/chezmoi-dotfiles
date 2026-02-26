require 'spec_helper'

RSpec.describe PantryManager::RecipeSearch do
  before do
    # Set up test recipes
    @recipe1 = create(:recipe,
      title: 'Marinara Sauce',
      source_url: 'http://example.com/1'
    )

    @recipe2 = create(:recipe,
      title: 'Garlic Bread',
      source_url: 'http://example.com/2'
    )

    @recipe3 = create(:recipe,
      title: 'Pasta Primavera',
      source_url: 'http://example.com/3'
    )

    # Set up ingredients
    @garlic = create(:ingredient, name: 'garlic')

    @tomato = create(:ingredient, name: 'tomato')

    @pasta = create(:ingredient, name: 'pasta')

    # Link ingredients to recipes
    create(:recipe_ingredient,
      recipe: @recipe1,
      ingredient: @garlic
    )
    create(:recipe_ingredient,
      recipe: @recipe1,
      ingredient: @tomato
    )

    create(:recipe_ingredient,
      recipe: @recipe2,
      ingredient: @garlic
    )

    create(:recipe_ingredient,
      recipe: @recipe3,
      ingredient: @garlic
    )
    create(:recipe_ingredient,
      recipe: @recipe3,
      ingredient: @pasta
    )
  end

  describe '.search_local' do
    context 'with text query' do
      it 'finds recipes by title using FTS' do
        results = described_class.search_local(query: 'marinara', limit: 10)
        expect(results.length).to eq(1)
        expect(results.first[:title]).to eq('Marinara Sauce')
      end

      it 'returns empty array when no matches found' do
        results = described_class.search_local(query: 'nonexistent', limit: 10)
        expect(results).to eq([])
      end

      it 'respects the limit parameter' do
        results = described_class.search_local(query: 'marinara OR garlic', limit: 1)
        expect(results.length).to be <= 1
      end
    end

    context 'with ingredient search' do
      it 'finds recipes containing a single ingredient' do
        results = described_class.search_local(ingredients: ['garlic'], limit: 10)
        expect(results.length).to eq(3)
        titles = results.map { |r| r[:title] }
        expect(titles).to include('Marinara Sauce', 'Garlic Bread', 'Pasta Primavera')
      end

      it 'finds recipes containing any of the given ingredients' do
        results = described_class.search_local(ingredients: ['garlic', 'tomato'], limit: 10)
        expect(results.length).to eq(3)
      end

      it 'orders results by match count (most matches first)' do
        results = described_class.search_local(ingredients: ['garlic', 'tomato'], limit: 10)
        expect(results.first[:title]).to eq('Marinara Sauce')
        expect(results.first[:match_count]).to eq(2)
      end

      it 'returns empty array when no ingredients provided' do
        results = described_class.search_local(ingredients: [], limit: 10)
        expect(results).to eq([])
      end

      it 'returns empty array when ingredient not found' do
        results = described_class.search_local(ingredients: ['nonexistent'], limit: 10)
        expect(results).to eq([])
      end
    end

    context 'result formatting' do
      it 'includes recipe metadata' do
        result = described_class.search_local(ingredients: ['garlic'], limit: 1).first
        expect(result).to have_key(:id)
        expect(result).to have_key(:title)
        expect(result).to have_key(:yield)
        expect(result).to have_key(:time)
        expect(result).to have_key(:source)
        expect(result[:source]).to eq('local')
      end

      it 'includes match count for ingredient searches' do
        result = described_class.search_local(ingredients: ['garlic', 'tomato'], limit: 1).first
        expect(result).to have_key(:match_count)
        expect(result[:match_count]).to be > 0
      end
    end
  end
end
