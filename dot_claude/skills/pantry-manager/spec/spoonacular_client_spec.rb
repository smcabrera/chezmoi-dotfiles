require 'spec_helper'

RSpec.describe PantryManager::SpoonacularClient do
  describe '.api_key' do
    context 'when API key is in environment' do
      before do
        ENV['SPOONACULAR_API_KEY'] = 'test_api_key'
      end

      after do
        ENV.delete('SPOONACULAR_API_KEY')
      end

      it 'returns the API key from environment' do
        expect(described_class.api_key).to eq('test_api_key')
      end
    end

    context 'when API key is not available' do
      before do
        ENV.delete('SPOONACULAR_API_KEY')
      end

      it 'returns nil or empty' do
        expect(described_class.api_key).to be_nil.or be_empty
      end
    end
  end

  describe '.search_by_ingredients' do
    context 'with valid API key' do
      let(:mock_response) do
        [
          {
            'id' => 123,
            'title' => 'Garlic Pasta',
            'usedIngredientCount' => 2,
            'missedIngredientCount' => 1
          },
          {
            'id' => 456,
            'title' => 'Chicken Stir Fry',
            'usedIngredientCount' => 3,
            'missedIngredientCount' => 0
          }
        ].to_json
      end

      before do
        allow(described_class).to receive(:api_key).and_return('test_key')
        stub_request(:get, "https://api.spoonacular.com/recipes/findByIngredients")
          .with(query: hash_including('apiKey' => 'test_key'))
          .to_return(status: 200, body: mock_response)
      end

      it 'returns formatted recipe results' do
        results = described_class.search_by_ingredients(['garlic', 'pasta'], number: 10)
        expect(results.length).to eq(2)
        expect(results.first[:title]).to eq('Garlic Pasta')
        expect(results.first[:source]).to eq('spoonacular')
      end

      it 'includes used and missed ingredient counts' do
        results = described_class.search_by_ingredients(['garlic'], number: 10)
        expect(results.first).to have_key(:used_ingredient_count)
        expect(results.first).to have_key(:missed_ingredient_count)
        expect(results.first[:used_ingredient_count]).to eq(2)
        expect(results.first[:missed_ingredient_count]).to eq(1)
      end

      it 'sends ingredients as comma-separated string' do
        described_class.search_by_ingredients(['garlic', 'pasta', 'tomato'], number: 5)
        expect(WebMock).to have_requested(:get, "https://api.spoonacular.com/recipes/findByIngredients")
          .with(query: hash_including('ingredients' => 'garlic,pasta,tomato'))
      end

      it 'respects the number parameter' do
        described_class.search_by_ingredients(['garlic'], number: 15)
        expect(WebMock).to have_requested(:get, "https://api.spoonacular.com/recipes/findByIngredients")
          .with(query: hash_including('number' => '15'))
      end
    end

    context 'without API key' do
      before do
        allow(described_class).to receive(:api_key).and_return(nil)
      end

      it 'returns empty array' do
        results = described_class.search_by_ingredients(['garlic'])
        expect(results).to eq([])
      end

      it 'does not make HTTP request' do
        described_class.search_by_ingredients(['garlic'])
        expect(WebMock).not_to have_requested(:get, /spoonacular/)
      end
    end

    context 'when API request fails' do
      before do
        allow(described_class).to receive(:api_key).and_return('test_key')
        stub_request(:get, "https://api.spoonacular.com/recipes/findByIngredients")
          .with(query: hash_including('apiKey' => 'test_key'))
          .to_return(status: 500, body: 'Server Error')
      end

      it 'returns empty array' do
        results = described_class.search_by_ingredients(['garlic'])
        expect(results).to eq([])
      end
    end

    context 'when API returns invalid JSON' do
      before do
        allow(described_class).to receive(:api_key).and_return('test_key')
        stub_request(:get, "https://api.spoonacular.com/recipes/findByIngredients")
          .with(query: hash_including('apiKey' => 'test_key'))
          .to_return(status: 200, body: 'invalid json')
      end

      it 'returns empty array' do
        results = described_class.search_by_ingredients(['garlic'])
        expect(results).to eq([])
      end
    end
  end

  describe '.get_recipe_details' do
    let(:recipe_id) { 123 }
    let(:mock_response) do
      {
        'id' => 123,
        'title' => 'Garlic Pasta',
        'readyInMinutes' => 30,
        'servings' => 4
      }.to_json
    end

    context 'with valid API key' do
      before do
        allow(described_class).to receive(:api_key).and_return('test_key')
        stub_request(:get, "https://api.spoonacular.com/recipes/#{recipe_id}/information")
          .with(query: hash_including('apiKey' => 'test_key'))
          .to_return(status: 200, body: mock_response)
      end

      it 'returns recipe details' do
        result = described_class.get_recipe_details(recipe_id)
        expect(result).to be_a(Hash)
        expect(result['title']).to eq('Garlic Pasta')
        expect(result['servings']).to eq(4)
      end
    end

    context 'without API key' do
      before do
        allow(described_class).to receive(:api_key).and_return(nil)
      end

      it 'returns nil' do
        result = described_class.get_recipe_details(recipe_id)
        expect(result).to be_nil
      end
    end

    context 'when API request fails' do
      before do
        allow(described_class).to receive(:api_key).and_return('test_key')
        stub_request(:get, "https://api.spoonacular.com/recipes/#{recipe_id}/information")
          .with(query: hash_including('apiKey' => 'test_key'))
          .to_return(status: 404, body: 'Not Found')
      end

      it 'returns nil' do
        result = described_class.get_recipe_details(recipe_id)
        expect(result).to be_nil
      end
    end
  end
end
