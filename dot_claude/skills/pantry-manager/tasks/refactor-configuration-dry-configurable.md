# Task: Refactor Configuration with dry-configurable

## Status: TODO

## Background

Currently, configuration values (API keys, model names, endpoints, etc.) are hardcoded throughout the codebase. This makes it difficult to:
- Change configuration without modifying code
- Support different environments (development, test, production)
- Allow users to customize settings
- Keep sensitive data out of the codebase

## Goals

1. Extract all configuration into a centralized, type-safe configuration system
2. Use the `dry-configurable` gem for robust configuration management
3. Support multiple configuration sources (ENV vars, config files, defaults)
4. Provide clear documentation of all configuration options
5. Maintain backward compatibility with existing ENV var usage

## Configuration Items to Extract

### API Configuration
- `ANTHROPIC_API_KEY` - API key for Claude
- `API_ENDPOINT` - Currently hardcoded as `https://api.anthropic.com/v1/messages`
- `MODEL` - Currently hardcoded as `claude-3-haiku-20240307`
- API timeout (currently 30 seconds)
- API version header (currently `2023-06-01`)

### Database Configuration
- Database path (currently `~/.local/share/pantry-manager/pantry.db`)
- Database connection options

### Application Settings
- Rate limiting delays (currently 2 seconds for recipe import)
- Default units for pantry items
- Pagination limits

## Implementation Plan

### 1. Add dry-configurable gem

Add to Gemfile:
```ruby
gem 'dry-configurable', '~> 1.0'
```

### 2. Create Configuration Module

Create `lib/pantry_manager/configuration.rb`:

```ruby
require 'dry-configurable'

module PantryManager
  extend Dry::Configurable

  # API Settings
  setting :anthropic do
    setting :api_key, default: ENV['ANTHROPIC_API_KEY']
    setting :endpoint, default: 'https://api.anthropic.com/v1/messages'
    setting :model, default: 'claude-3-haiku-20240307'
    setting :timeout, default: 30
    setting :version, default: '2023-06-01'
  end

  # Database Settings
  setting :database do
    setting :path, default: File.expand_path('~/.local/share/pantry-manager/pantry.db')
  end

  # Application Settings
  setting :rate_limiting do
    setting :recipe_import_delay, default: 2
  end

  setting :parsing do
    setting :max_tokens, default: 1024
  end
end
```

### 3. Create Configuration Loader

Create `lib/pantry_manager/config_loader.rb`:

```ruby
module PantryManager
  class ConfigLoader
    def self.load!
      # Load from environment
      load_from_env
      
      # Load from config file if exists
      config_file = File.expand_path('~/.config/pantry-manager/config.yml')
      load_from_file(config_file) if File.exist?(config_file)
      
      # Allow per-project overrides
      local_config = '.pantry-manager.yml'
      load_from_file(local_config) if File.exist?(local_config)
    end

    private

    def self.load_from_env
      # Override from environment variables
      if ENV['ANTHROPIC_MODEL']
        PantryManager.config.anthropic.model = ENV['ANTHROPIC_MODEL']
      end
      
      if ENV['PANTRY_DB_PATH']
        PantryManager.config.database.path = ENV['PANTRY_DB_PATH']
      end
    end

    def self.load_from_file(path)
      require 'yaml'
      config = YAML.load_file(path)
      
      # Deep merge configuration
      if config['anthropic']
        config['anthropic'].each do |key, value|
          PantryManager.config.anthropic.send("#{key}=", value)
        end
      end
      
      # ... handle other sections
    end
  end
end
```

### 4. Update Existing Code

Update `lib/natural_language_parser.rb`:
```ruby
module PantryManager
  class NaturalLanguageParser
    def self.call_api(api_key, prompt)
      config = PantryManager.config.anthropic
      
      uri = URI(config.endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = config.timeout

      request = Net::HTTP::Post.new(uri.path)
      request['Content-Type'] = 'application/json'
      request['x-api-key'] = api_key || config.api_key
      request['anthropic-version'] = config.version

      request.body = {
        model: config.model,
        max_tokens: PantryManager.config.parsing.max_tokens,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ]
      }.to_json
      
      # ... rest of implementation
    end
  end
end
```

### 5. Configuration File Format

Example `~/.config/pantry-manager/config.yml`:
```yaml
anthropic:
  model: claude-3-5-sonnet-20241022
  timeout: 60

database:
  path: ~/Documents/pantry.db

rate_limiting:
  recipe_import_delay: 1
```

### 6. Update bin/pantry-manager

Add configuration loading at startup:
```ruby
#!/usr/bin/env ruby

# ... existing requires ...
require 'pantry_manager/configuration'
require 'pantry_manager/config_loader'

# Load configuration
PantryManager::ConfigLoader.load!

# ... rest of file ...
```

### 7. Add Configuration Command

Add to CLI:
```ruby
when 'config'
  handle_config(command_args)
```

```ruby
def self.handle_config(args)
  if args.empty?
    puts "Current Configuration:"
    puts
    puts "Anthropic:"
    puts "  API Key: #{PantryManager.config.anthropic.api_key ? '[SET]' : '[NOT SET]'}"
    puts "  Model: #{PantryManager.config.anthropic.model}"
    puts "  Endpoint: #{PantryManager.config.anthropic.endpoint}"
    puts
    puts "Database:"
    puts "  Path: #{PantryManager.config.database.path}"
    # ... etc
  elsif args[0] == 'set'
    # Allow setting config values
    # pantry-manager config set anthropic.model claude-3-opus-20240229
  end
end
```

## Benefits

1. **Type Safety**: dry-configurable provides type coercion and validation
2. **Documentation**: Settings are self-documenting
3. **Flexibility**: Easy to add new configuration options
4. **Testing**: Can easily override settings in tests
5. **Environment Support**: Different configs for dev/test/prod
6. **User Customization**: Users can override defaults without code changes

## Testing

Add tests for configuration:
```ruby
RSpec.describe PantryManager::Configuration do
  it "loads default values" do
    expect(PantryManager.config.anthropic.model).to eq('claude-3-haiku-20240307')
  end
  
  it "overrides from environment" do
    ENV['ANTHROPIC_MODEL'] = 'test-model'
    PantryManager::ConfigLoader.load!
    expect(PantryManager.config.anthropic.model).to eq('test-model')
  end
end
```

## Migration Path

1. Implement configuration system alongside existing code
2. Update one component at a time to use new config
3. Add deprecation warnings for direct ENV access
4. Remove old hardcoded values after migration complete

## Success Criteria

- [ ] All hardcoded configuration extracted
- [ ] Configuration can be loaded from multiple sources
- [ ] Clear documentation of all settings
- [ ] Backward compatibility maintained
- [ ] Tests for configuration loading
- [ ] Config validation and error messages