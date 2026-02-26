require 'spec_helper'

RSpec.describe PantryManager::RecipeImporter do

  describe '.import' do
    let(:nyt_url) { 'https://cooking.nytimes.com/recipes/test' }
    let(:other_url) { 'https://example.com/recipe' }

    context 'with successful NYT recipe import' do
      let(:mock_nyt_data) do
        {
          source_url: nyt_url,
          title: 'Test Recipe',
          yield: '4 servings',
          total_time: 'PT30M',
          ingredients: ['2 cups flour', '1 cup sugar', '3 eggs'],
          steps: ['Mix ingredients', 'Bake'],
          raw_data: '{"title":"Test Recipe"}'
        }
      end

      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_return(mock_nyt_data)
      end

      it 'imports the recipe successfully' do
        result = described_class.import(nyt_url)
        expect(result[:success]).to be true
        expect(result[:title]).to eq('Test Recipe')
      end

      it 'stores recipe in database' do
        expect {
          described_class.import(nyt_url)
        }.to change { PantryManager::Recipe.count }.by(1)
      end

      it 'stores recipe metadata' do
        described_class.import(nyt_url)
        recipe = PantryManager::Recipe.find_by(source_url: nyt_url)
        expect(recipe.title).to eq('Test Recipe')
        expect(recipe.yield_text).to eq('4 servings')
        expect(recipe.total_time).to eq('PT30M')
        expect(recipe.raw_data).to eq('{"title":"Test Recipe"}')
      end

      it 'parses and stores ingredients' do
        result = described_class.import(nyt_url)
        expect(result[:ingredient_count]).to eq(3)
      end

      it 'creates ingredient records' do
        expect {
          described_class.import(nyt_url)
        }.to change { PantryManager::Ingredient.count }.by(3)
      end

      it 'creates recipe_ingredients links' do
        result = described_class.import(nyt_url)
        recipe_id = result[:recipe_id]
        
        links = PantryManager::RecipeIngredient.where(recipe_id: recipe_id)
        expect(links.count).to eq(3)
      end

      it 'stores parsed ingredient data' do
        result = described_class.import(nyt_url)
        recipe_id = result[:recipe_id]
        
        flour = PantryManager::RecipeIngredient
          .joins(:ingredient)
          .where(recipe_id: recipe_id, ingredients: { name: 'flour' })
          .first
        
        expect(flour.quantity).to eq('2')
        expect(flour.unit).to eq('cups')
        expect(flour.original_text).to eq('2 cups flour')
      end

      it 'returns parser name used' do
        result = described_class.import(nyt_url)
        expect(result[:parser]).to eq('NYTParser')
      end
    end

    context 'with schema.org recipe import' do
      let(:mock_schema_data) do
        {
          source_url: other_url,
          title: 'Schema Recipe',
          yield: '2 servings',
          total_time: 'PT15M',
          ingredients: ['1 cup rice', '2 cups water'],
          steps: ['Boil water', 'Add rice'],
          raw_data: '{"name":"Schema Recipe"}'
        }
      end

      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(other_url).and_return(false)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:can_parse?).with(other_url).and_return(true)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:parse).with(other_url).and_return(mock_schema_data)
      end

      it 'falls back to SchemaOrgParser' do
        result = described_class.import(other_url)
        expect(result[:success]).to be true
        expect(result[:parser]).to eq('SchemaOrgParser')
      end

      it 'imports the recipe correctly' do
        result = described_class.import(other_url)
        expect(result[:title]).to eq('Schema Recipe')
        expect(result[:ingredient_count]).to eq(2)
      end
    end

    context 'with duplicate recipe' do
      let!(:existing_recipe) do
        PantryManager::Recipe.create!(
          source_url: nyt_url,
          title: 'Existing Recipe',
          created_at: Time.now,
          updated_at: Time.now
        )
      end

      let(:mock_nyt_data) do
        {
          source_url: nyt_url,
          title: 'Test Recipe',
          yield: '4 servings',
          total_time: 'PT30M',
          ingredients: ['2 cups flour'],
          raw_data: '{}'
        }
      end

      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_return(mock_nyt_data)
      end

      it 'returns an error' do
        result = described_class.import(nyt_url)
        expect(result[:error]).to include('already imported')
      end

      it 'returns the existing recipe ID' do
        result = described_class.import(nyt_url)
        expect(result[:recipe_id]).to eq(existing_recipe.id)
      end

      it 'does not create duplicate records' do
        expect {
          described_class.import(nyt_url)
        }.not_to change { PantryManager::Recipe.count }
      end
    end

    context 'when parser returns nil' do
      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_return(nil)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:parse).with(nyt_url).and_return(nil)
      end

      it 'returns an error' do
        result = described_class.import(nyt_url)
        expect(result[:error]).to include('Could not parse recipe')
      end
    end

    context 'when parser raises an exception' do
      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_raise(StandardError, 'Parse error')
        
        # Fallback parser returns valid data
        mock_data = {
          source_url: nyt_url,
          title: 'Fallback Recipe',
          ingredients: ['1 ingredient'],
          raw_data: '{}'
        }
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:parse).with(nyt_url).and_return(mock_data)
      end

      it 'tries the next parser' do
        result = described_class.import(nyt_url)
        expect(result[:success]).to be true
        expect(result[:title]).to eq('Fallback Recipe')
      end
    end

    context 'with ingredients that have no name' do
      let(:mock_data) do
        {
          source_url: nyt_url,
          title: 'Test Recipe',
          ingredients: ['Salt to taste', ''],  # Second one will parse to empty name
          raw_data: '{}'
        }
      end

      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_return(mock_data)
      end

      it 'skips ingredients with empty names' do
        result = described_class.import(nyt_url)
        # Only 'salt' should be imported, empty string should be skipped
        expect(result[:ingredient_count]).to be <= 1
      end
    end

    context 'with duplicate ingredients in same recipe' do
      let(:mock_data) do
        {
          source_url: nyt_url,
          title: 'Test Recipe',
          yield: '2 servings',
          total_time: 'PT15M',
          ingredients: ['2 cups flour', '1 cup sugar'],
          raw_data: '{}'
        }
      end

      before do
        allow(PantryManager::Parsers::NYTParser).to receive(:can_parse?).with(nyt_url).and_return(true)
        allow(PantryManager::Parsers::NYTParser).to receive(:parse).with(nyt_url).and_return(mock_data)
        allow(PantryManager::Parsers::SchemaOrgParser).to receive(:can_parse?).with(nyt_url).and_return(false)
      end

      it 'creates multiple ingredient records for different ingredients' do
        expect {
          described_class.import(nyt_url)
        }.to change { PantryManager::Ingredient.count }.by(2)
      end

      it 'creates recipe_ingredient links for each ingredient' do
        result = described_class.import(nyt_url)
        expect(result[:ingredient_count]).to eq(2)
        expect(result[:success]).to be true
      end
    end
  end
end
