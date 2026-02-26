require 'bundler/setup'
require 'fileutils'
require 'webmock/rspec'
require 'database_cleaner/active_record'
require 'factory_bot'

# Set test environment
ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

# Require lib files
require_relative '../lib/database'
require_relative '../lib/models'
require_relative '../lib/cli'

# Load all factories
FactoryBot.find_definitions

RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  # Set up test database
  config.before(:suite) do
    # Establish connection for test environment
    PantryManager::ActiveRecordSetup.establish_connection

    # Load schema first
    load File.expand_path('../db/schema.rb', __dir__)

    # Then manually create the FTS table and triggers (not captured in schema.rb)
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE VIRTUAL TABLE IF NOT EXISTS recipes_fts USING fts5(
        title,
        content='recipes',
        content_rowid='id'
      );
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TRIGGER IF NOT EXISTS recipes_fts_insert AFTER INSERT ON recipes BEGIN
        INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
      END;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TRIGGER IF NOT EXISTS recipes_fts_delete AFTER DELETE ON recipes BEGIN
        DELETE FROM recipes_fts WHERE rowid = old.id;
      END;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TRIGGER IF NOT EXISTS recipes_fts_update AFTER UPDATE ON recipes BEGIN
        DELETE FROM recipes_fts WHERE rowid = old.id;
        INSERT INTO recipes_fts(rowid, title) VALUES (new.id, new.title);
      END;
    SQL

    # Configure database_cleaner
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Disable external HTTP requests (webmock)
  WebMock.disable_net_connect!(allow_localhost: true)

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
