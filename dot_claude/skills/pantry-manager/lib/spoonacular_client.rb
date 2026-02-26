require 'faraday'
require 'faraday/follow_redirects'
require 'json'

module PantryManager
  class SpoonacularClient
    BASE_URL = 'https://api.spoonacular.com'

    def self.api_key
      # Try ENV first, then config file
      ENV['SPOONACULAR_API_KEY'] || read_config['spoonacular_api_key']
    end

    def self.search_by_ingredients(ingredients, number: 10)
      return [] unless api_key

      conn = Faraday.new(url: BASE_URL) do |f|
        f.response :follow_redirects
      end

      response = conn.get('/recipes/findByIngredients') do |req|
        req.params['apiKey'] = api_key
        req.params['ingredients'] = ingredients.join(',')
        req.params['number'] = number
        req.params['ranking'] = 1  # Maximize used ingredients
      end

      return [] unless response.success?

      JSON.parse(response.body).map { |recipe| format_recipe(recipe) }
    rescue => e
      # Log error but don't crash
      puts "Spoonacular API error: #{e.message}"
      []
    end

    def self.search_by_query(query, number: 10)
      return [] unless api_key

      conn = Faraday.new(url: BASE_URL) do |f|
        f.response :follow_redirects
      end

      response = conn.get('/recipes/complexSearch') do |req|
        req.params['apiKey'] = api_key
        req.params['query'] = query
        req.params['number'] = number
      end

      return [] unless response.success?

      JSON.parse(response.body).fetch('results', []).map do |recipe|
        { id: recipe['id'], title: recipe['title'], source: 'spoonacular' }
      end
    rescue => e
      puts "Spoonacular API error: #{e.message}"
      []
    end

    def self.get_recipe_details(id)
      return nil unless api_key

      conn = Faraday.new(url: BASE_URL) do |f|
        f.response :follow_redirects
      end

      response = conn.get("/recipes/#{id}/information") do |req|
        req.params['apiKey'] = api_key
      end

      return nil unless response.success?
      JSON.parse(response.body)
    rescue => e
      puts "Spoonacular API error: #{e.message}"
      nil
    end

    private

    def self.format_recipe(data)
      {
        id: data['id'],
        title: data['title'],
        used_ingredient_count: data['usedIngredientCount'],
        missed_ingredient_count: data['missedIngredientCount'],
        source: 'spoonacular'
      }
    end

    def self.read_config
      config_path = File.expand_path('~/.pantry-manager/config.json')
      return {} unless File.exist?(config_path)
      JSON.parse(File.read(config_path))
    rescue => e
      {}
    end
  end
end
