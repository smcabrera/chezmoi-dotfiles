require 'spec_helper'

RSpec.describe PantryManager::Parsers::NYTParser do
  describe '.can_parse?' do
    it 'returns true for NYT Cooking URLs' do
      url = 'https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce'
      expect(described_class.can_parse?(url)).to be true
    end

    it 'returns false for non-NYT URLs' do
      url = 'https://www.allrecipes.com/recipe/12345'
      expect(described_class.can_parse?(url)).to be false
    end
  end

  describe '.parse' do
    let(:nyt_url) { 'https://cooking.nytimes.com/recipes/1015987-classic-marinara-sauce' }
    
    let(:mock_html) do
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <script id="__NEXT_DATA__" type="application/json">
              {
                "props": {
                  "pageProps": {
                    "recipe": {
                      "title": "Classic Marinara Sauce",
                      "recipeYield": "4 servings",
                      "totalTime": "PT30M",
                      "ingredients": [
                        {
                          "ingredients": [
                            {"quantity": "1/4", "text": "cup olive oil"},
                            {"quantity": "3", "text": "cloves garlic, minced"},
                            {"quantity": "1", "text": "28-ounce can tomatoes"}
                          ]
                        }
                      ],
                      "steps": [
                        {
                          "steps": [
                            {"description": "Heat oil in a large pan."},
                            {"description": "Add garlic and cook until fragrant."}
                          ]
                        }
                      ]
                    }
                  }
                }
              }
            </script>
          </head>
          <body></body>
        </html>
      HTML
    end

    before do
      stub_request(:get, nyt_url)
        .to_return(status: 200, body: mock_html)
    end

    it 'extracts recipe title' do
      result = described_class.parse(nyt_url)
      expect(result[:title]).to eq('Classic Marinara Sauce')
    end

    it 'extracts yield information' do
      result = described_class.parse(nyt_url)
      expect(result[:yield]).to eq('4 servings')
    end

    it 'extracts total time' do
      result = described_class.parse(nyt_url)
      expect(result[:total_time]).to eq('PT30M')
    end

    it 'extracts ingredients from groups' do
      result = described_class.parse(nyt_url)
      expect(result[:ingredients]).to include('1/4 cup olive oil')
      expect(result[:ingredients]).to include('3 cloves garlic, minced')
      expect(result[:ingredients]).to include('1 28-ounce can tomatoes')
    end

    it 'extracts steps from groups' do
      result = described_class.parse(nyt_url)
      expect(result[:steps]).to include('Heat oil in a large pan.')
      expect(result[:steps]).to include('Add garlic and cook until fragrant.')
    end

    it 'includes source URL' do
      result = described_class.parse(nyt_url)
      expect(result[:source_url]).to eq(nyt_url)
    end

    it 'includes raw data as JSON' do
      result = described_class.parse(nyt_url)
      expect(result[:raw_data]).to be_a(String)
      expect(JSON.parse(result[:raw_data])).to have_key('title')
    end

    context 'when __NEXT_DATA__ is missing' do
      let(:invalid_html) { '<html><body>No recipe data</body></html>' }

      before do
        stub_request(:get, nyt_url)
          .to_return(status: 200, body: invalid_html)
      end

      it 'returns nil' do
        expect(described_class.parse(nyt_url)).to be_nil
      end
    end
  end

  describe 'rate limiting' do
    let(:url) { 'https://cooking.nytimes.com/recipes/test' }
    let(:mock_html) do
      '<html><script id="__NEXT_DATA__">{"props":{"pageProps":{"recipe":{"title":"Test"}}}}</script></html>'
    end

    before do
      stub_request(:get, url).to_return(status: 200, body: mock_html)
      described_class.instance_variable_set(:@last_request_time, nil)
    end

    it 'enforces minimum time between requests' do
      start_time = Time.now
      described_class.parse(url)
      described_class.parse(url)
      elapsed = Time.now - start_time

      expect(elapsed).to be >= described_class::RATE_LIMIT_SECONDS
    end
  end
end
