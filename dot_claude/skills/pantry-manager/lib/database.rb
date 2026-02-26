require 'active_record'
require_relative 'active_record_setup'

# Load all models
Dir[File.expand_path('../app/models/*.rb', __dir__)].sort.each { |f| require f }

module PantryManager
  class Database
    # For backward compatibility, keep DB_PATH constant
    DB_PATH = File.expand_path('~/.local/share/pantry-manager/pantry.db')

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.setup
      PantryManager::ActiveRecordSetup.establish_connection
      connection
    end
  end
end

# Establish connection when this file is loaded
PantryManager::ActiveRecordSetup.establish_connection unless defined?(RSpec)
