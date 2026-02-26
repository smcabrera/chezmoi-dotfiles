require 'spec_helper'

RSpec.describe PantryManager::Parsers::SchemaOrgParser do
  describe '.can_parse?' do
    it 'returns true for any URL (fallback parser)' do
      expect(described_class.can_parse?('https://example.com/recipe')).to be true
      expect(described_class.can_parse?('https://allrecipes.com/recipe/123')).to be true
    end
  end

  describe '.parse' do
    let(:url) { 'https://example.com/recipe' }

    context 'with valid schema.org JSON-LD' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": "Recipe",
                  "name": "Chocolate Chip Cookies",
                  "recipeYield": "24 cookies",
                  "totalTime": "PT45M",
                  "recipeIngredient": [
                    "2 cups flour",
                    "1 cup sugar",
                    "1/2 cup butter"
                  ],
                  "recipeInstructions": [
                    {"@type": "HowToStep", "text": "Mix dry ingredients."},
                    {"@type": "HowToStep", "text": "Add wet ingredients."}
                  ]
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'extracts recipe title' do
        result = described_class.parse(url)
        expect(result[:title]).to eq('Chocolate Chip Cookies')
      end

      it 'extracts yield information' do
        result = described_class.parse(url)
        expect(result[:yield]).to eq('24 cookies')
      end

      it 'extracts total time' do
        result = described_class.parse(url)
        expect(result[:total_time]).to eq('PT45M')
      end

      it 'extracts ingredients array' do
        result = described_class.parse(url)
        expect(result[:ingredients]).to eq(['2 cups flour', '1 cup sugar', '1/2 cup butter'])
      end

      it 'extracts steps from HowToStep objects' do
        result = described_class.parse(url)
        expect(result[:steps]).to eq(['Mix dry ingredients.', 'Add wet ingredients.'])
      end

      it 'includes source URL' do
        result = described_class.parse(url)
        expect(result[:source_url]).to eq(url)
      end
    end

    context 'with @graph structure' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@graph": [
                    {"@type": "WebSite", "name": "Example Site"},
                    {
                      "@type": "Recipe",
                      "name": "Test Recipe",
                      "recipeYield": "2 servings",
                      "recipeIngredient": ["ingredient 1"],
                      "recipeInstructions": ["Step 1"]
                    }
                  ]
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'finds recipe in @graph array' do
        result = described_class.parse(url)
        expect(result[:title]).to eq('Test Recipe')
      end
    end

    context 'with @type as array' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": ["Recipe", "Article"],
                  "name": "Multi-Type Recipe",
                  "recipeIngredient": ["ingredient 1"],
                  "recipeInstructions": ["Step 1"]
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'recognizes Recipe in @type array' do
        result = described_class.parse(url)
        expect(result[:title]).to eq('Multi-Type Recipe')
      end
    end

    context 'with string instructions' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": "Recipe",
                  "name": "Simple Recipe",
                  "recipeIngredient": ["ingredient 1"],
                  "recipeInstructions": "Mix everything together."
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'handles string instructions' do
        result = described_class.parse(url)
        expect(result[:steps]).to eq(['Mix everything together.'])
      end
    end

    context 'with array of string instructions' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": "Recipe",
                  "name": "Simple Recipe",
                  "recipeIngredient": ["ingredient 1"],
                  "recipeInstructions": ["Step 1", "Step 2"]
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'handles array of strings' do
        result = described_class.parse(url)
        expect(result[:steps]).to eq(['Step 1', 'Step 2'])
      end
    end

    context 'when no recipe is found' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {
                  "@context": "https://schema.org",
                  "@type": "Article",
                  "name": "Not a Recipe"
                }
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'returns nil' do
        expect(described_class.parse(url)).to be_nil
      end
    end

    context 'when JSON is invalid' do
      let(:mock_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <script type="application/ld+json">
                {invalid json}
              </script>
            </head>
            <body></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, url).to_return(status: 200, body: mock_html)
      end

      it 'returns nil' do
        expect(described_class.parse(url)).to be_nil
      end
    end
  end
end
