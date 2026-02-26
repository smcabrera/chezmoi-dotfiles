require 'active_record'
require 'yaml'
require 'erb'
require 'logger'
require 'fileutils'

module PantryManager
  class ActiveRecordSetup
    def self.establish_connection
      env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      config_path = File.expand_path('../config/database.yml', __dir__)
      
      # Load and parse YAML with ERB processing
      unless File.exist?(config_path)
        raise "Database configuration not found: #{config_path}"
      end
      
      yaml_content = ERB.new(File.read(config_path)).result
      config_hash = YAML.safe_load(yaml_content, aliases: true)
      config = config_hash[env]
      
      unless config
        raise "No database configuration found for environment: #{env}"
      end
      
      # Ensure database directory exists
      db_path = config['database']
      if db_path
        FileUtils.mkdir_p(File.dirname(db_path))
      end
      
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.logger = Logger.new(STDOUT) if env == 'development'
    end
  end
end
