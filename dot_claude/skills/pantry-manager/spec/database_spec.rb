require 'spec_helper'

RSpec.describe PantryManager::Database do
  describe '.connection' do
    it 'creates a database file' do
      described_class.connection
      expect(File.exist?(described_class::DB_PATH)).to be true
    end

    it 'returns an ActiveRecord connection adapter' do
      db = described_class.connection
      expect(db).to be_a(ActiveRecord::ConnectionAdapters::AbstractAdapter)
    end

    it 'is connected to the database' do
      db = described_class.connection
      expect(db.active?).to be true
    end
  end

  describe 'schema' do
    it 'creates the recipes table' do
      expect(ActiveRecord::Base.connection.table_exists?(:recipes)).to be true
    end

    it 'creates the ingredients table' do
      expect(ActiveRecord::Base.connection.table_exists?(:ingredients)).to be true
    end

    it 'creates the recipe_ingredients table' do
      expect(ActiveRecord::Base.connection.table_exists?(:recipe_ingredients)).to be true
    end

    it 'creates the pantry_items table' do
      expect(ActiveRecord::Base.connection.table_exists?(:pantry_items)).to be true
    end

    it 'creates the favorites table' do
      expect(ActiveRecord::Base.connection.table_exists?(:favorites)).to be true
    end

    it 'has proper indexes on recipes table' do
      indexes = ActiveRecord::Base.connection.indexes(:recipes)
      index_names = indexes.map(&:name)
      expect(index_names).to include('index_recipes_on_source_url')
    end

    it 'has proper indexes on ingredients table' do
      indexes = ActiveRecord::Base.connection.indexes(:ingredients)
      index_names = indexes.map(&:name)
      expect(index_names).to include('index_ingredients_on_name')
    end

    it 'has proper indexes on recipe_ingredients table' do
      indexes = ActiveRecord::Base.connection.indexes(:recipe_ingredients)
      index_names = indexes.map(&:name)
      expect(index_names).to include('index_recipe_ingredients_on_recipe_id')
      expect(index_names).to include('index_recipe_ingredients_on_ingredient_id')
    end
  end
end
