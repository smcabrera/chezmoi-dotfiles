require 'spec_helper'

RSpec.describe PantryManager::MealPlanner do
  before do
    # Create test recipes
    @recipe1 = create(:recipe,
      title: 'Marinara Sauce',
      source_url: 'http://example.com/1',
      yield_text: '4 servings',
      total_time: '30 min'
    )

    @recipe2 = create(:recipe,
      title: 'Garlic Bread',
      source_url: 'http://example.com/2',
      yield_text: '6 servings',
      total_time: '15 min'
    )

    @recipe3 = create(:recipe,
      title: 'Pasta Primavera',
      source_url: 'http://example.com/3',
      yield_text: '4 servings',
      total_time: '25 min'
    )

    # Create ingredients
    @garlic = create(:ingredient, name: 'garlic')
    @tomato = create(:ingredient, name: 'tomato')
    @pasta = create(:ingredient, name: 'pasta')
    @oil = create(:ingredient, name: 'olive oil')

    # Link ingredients to recipes
    create(:recipe_ingredient,
      recipe: @recipe1,
      ingredient: @garlic,
      quantity: '3',
      unit: 'cloves'
    )
    create(:recipe_ingredient,
      recipe: @recipe1,
      ingredient: @tomato,
      quantity: '4',
      unit: 'whole'
    )
    create(:recipe_ingredient,
      recipe: @recipe1,
      ingredient: @oil,
      quantity: '1/4',
      unit: 'cup'
    )

    PantryManager::RecipeIngredient.create!(
      recipe: @recipe2,
      ingredient: @garlic,
      quantity: '4',
      unit: 'cloves'
    )
    PantryManager::RecipeIngredient.create!(
      recipe: @recipe2,
      ingredient: @oil,
      quantity: '1/2',
      unit: 'cup'
    )

    PantryManager::RecipeIngredient.create!(
      recipe: @recipe3,
      ingredient: @garlic,
      quantity: '2',
      unit: 'cloves'
    )
    PantryManager::RecipeIngredient.create!(
      recipe: @recipe3,
      ingredient: @pasta,
      quantity: '1',
      unit: 'pound'
    )
    PantryManager::RecipeIngredient.create!(
      recipe: @recipe3,
      ingredient: @oil,
      quantity: '2',
      unit: 'tablespoons'
    )
  end

  describe '.generate_plan' do
    context 'with pantry items' do
      let(:pantry_items) { ['garlic', 'olive oil'] }

      it 'returns a plan data hash' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: pantry_items)
        expect(result).to have_key(:prompt)
        expect(result).to have_key(:candidates)
        expect(result).to have_key(:pantry)
      end

      it 'includes the pantry items' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: pantry_items)
        expect(result[:pantry]).to eq(pantry_items)
      end

      it 'includes candidate recipes' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: pantry_items)
        expect(result[:candidates]).to be_an(Array)
        expect(result[:candidates]).not_to be_empty
      end

      it 'includes detailed recipe information with ingredients' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: pantry_items)
        candidate = result[:candidates].first
        expect(candidate).to have_key(:title)
        expect(candidate).to have_key(:ingredients)
        expect(candidate[:ingredients]).to be_an(Array)
      end

      it 'generates a selection prompt for Claude' do
        result = described_class.generate_plan(num_meals: 3, pantry_items: pantry_items)
        expect(result[:prompt]).to be_a(String)
        expect(result[:prompt]).to include('3 recipes')
        expect(result[:prompt]).to include('garlic')
        expect(result[:prompt]).to include('olive oil')
      end

      it 'limits candidates to reasonable number' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: pantry_items)
        expect(result[:candidates].length).to be <= 30
      end
    end

    context 'with empty pantry' do
      it 'fetches recipes without filtering by ingredients' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: [])
        expect(result[:pantry]).to eq([])
        expect(result[:candidates]).not_to be_empty
      end

      it 'still includes recipe details' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: [])
        candidate = result[:candidates].first
        expect(candidate).to have_key(:ingredients)
      end
    end

    context 'when no recipes found' do
      before do
        PantryManager::RecipeIngredient.destroy_all
        PantryManager::Recipe.destroy_all
      end

      it 'returns an error' do
        result = described_class.generate_plan(num_meals: 2, pantry_items: ['garlic'])
        expect(result).to have_key(:error)
        expect(result[:error]).to include('Not enough recipes found')
      end
    end

    context 'with fetching from database' do
      before do
        # Add pantry items
        PantryManager::PantryItem.create!(
          ingredient: @garlic,
          quantity: '5',
          unit: 'cloves'
        )
        PantryManager::PantryItem.create!(
          ingredient: @oil,
          quantity: '1',
          unit: 'cup'
        )
      end

      it 'fetches pantry items from database when none provided' do
        result = described_class.generate_plan(num_meals: 2)
        expect(result[:pantry]).to include('garlic', 'olive oil')
      end
    end
  end
end
