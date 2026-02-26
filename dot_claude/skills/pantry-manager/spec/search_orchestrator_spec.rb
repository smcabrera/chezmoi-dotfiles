require 'spec_helper'

RSpec.describe PantryManager::SearchOrchestrator do
  describe '.search' do
    before do
      # Create test recipes (need at least MIN_LOCAL_RESULTS = 5 for "sufficient" tests)
      garlic = create(:ingredient, name: 'garlic')

      # Create 5 recipes all containing garlic
      5.times do |i|
        recipe = create(:recipe, title: "Local Recipe #{i + 1}")
        create(:recipe_ingredient, recipe: recipe, ingredient: garlic)
      end
    end

    context 'when local results are sufficient' do
      it 'returns only local results' do
        results = described_class.search(ingredients: ['garlic'], limit: 10)
        expect(results.length).to eq(5)
        expect(results.all? { |r| r[:source] == 'local' }).to be true
      end

      it 'does not call Spoonacular API' do
        allow(PantryManager::SpoonacularClient).to receive(:search_by_ingredients)
        described_class.search(ingredients: ['garlic'], limit: 10)
        expect(PantryManager::SpoonacularClient).not_to have_received(:search_by_ingredients)
      end
    end

    context 'when local results are insufficient' do
      let(:api_results) do
        [
          { id: 1, title: 'API Recipe 1', source: 'spoonacular' },
          { id: 2, title: 'API Recipe 2', source: 'spoonacular' },
          { id: 3, title: 'API Recipe 3', source: 'spoonacular' }
        ]
      end

      before do
        # Clear existing recipes to have fewer than MIN_LOCAL_RESULTS
        PantryManager::RecipeIngredient.destroy_all
        PantryManager::Recipe.destroy_all
        PantryManager::Ingredient.destroy_all

        # Add just 2 recipes (less than MIN_LOCAL_RESULTS of 5)
        garlic = create(:ingredient, name: 'garlic')

        2.times do |i|
          recipe = create(:recipe, title: "Local Recipe #{i + 1}")
          create(:recipe_ingredient, recipe: recipe, ingredient: garlic)
        end

        allow(PantryManager::SpoonacularClient).to receive(:search_by_ingredients).and_return(api_results)
      end

      it 'supplements with Spoonacular API results' do
        results = described_class.search(ingredients: ['garlic'], limit: 10)
        local_count = results.count { |r| r[:source] == 'local' }
        api_count = results.count { |r| r[:source] == 'spoonacular' }

        expect(local_count).to eq(2)
        expect(api_count).to eq(3)
      end

      it 'calls Spoonacular with correct parameters' do
        described_class.search(ingredients: ['garlic', 'tomato'], limit: 10)
        expect(PantryManager::SpoonacularClient).to have_received(:search_by_ingredients)
          .with(['garlic', 'tomato'], number: 8)  # 10 - 2 local results
      end

      it 'respects the limit parameter' do
        results = described_class.search(ingredients: ['garlic'], limit: 3)
        expect(results.length).to be <= 3
      end
    end

    context 'when no ingredients provided' do
      it 'returns only local results without calling API' do
        allow(PantryManager::SpoonacularClient).to receive(:search_by_ingredients)
        results = described_class.search(limit: 10)
        expect(PantryManager::SpoonacularClient).not_to have_received(:search_by_ingredients)
      end
    end

    context 'when Spoonacular API is unavailable' do
      before do
        # Clear recipes to trigger API call
        PantryManager::RecipeIngredient.destroy_all
        PantryManager::Recipe.destroy_all
        PantryManager::Ingredient.destroy_all

        # Create just 1 recipe (less than MIN_LOCAL_RESULTS)
        recipe = create(:recipe, title: 'Local Recipe', source_url: 'http://example.com/1')
        garlic = create(:ingredient, name: 'garlic')
        create(:recipe_ingredient, recipe: recipe, ingredient: garlic)

        allow(PantryManager::SpoonacularClient).to receive(:search_by_ingredients).and_return([])
      end

      it 'returns only local results' do
        results = described_class.search(ingredients: ['garlic'], limit: 10)
        expect(results.all? { |r| r[:source] == 'local' }).to be true
      end
    end
  end
end
