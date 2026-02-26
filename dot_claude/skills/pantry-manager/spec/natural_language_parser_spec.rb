require 'spec_helper'
require 'natural_language_parser'

RSpec.describe PantryManager::NaturalLanguageParser do
  describe '.parse' do
    let(:api_key) { 'test-api-key-123' }

    before do
      ENV['ANTHROPIC_API_KEY'] = api_key
    end

    after do
      ENV.delete('ANTHROPIC_API_KEY')
    end

    context 'when API key is not set' do
      before do
        ENV.delete('ANTHROPIC_API_KEY')
      end

      it 'raises ParseError' do
        expect {
          described_class.parse('some text')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::ParseError,
          /ANTHROPIC_API_KEY/
        )
      end
    end

    context 'with successful API responses' do
      it 'parses "four roma tomatoes and a bag of kale"' do
        response_body = {
          content: [
            {
              text: '[{"name": "roma tomatoes", "quantity": "4", "unit": "whole"}, {"name": "kale", "quantity": "1", "unit": "bag"}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('four roma tomatoes and a bag of kale')

        expect(result).to eq([
          { name: 'roma tomatoes', quantity: '4', unit: 'whole' },
          { name: 'kale', quantity: '1', unit: 'bag' }
        ])
      end

      it 'parses "2 cans of crushed tomatoes"' do
        response_body = {
          content: [
            {
              text: '[{"name": "crushed tomatoes", "quantity": "2", "unit": "can"}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('2 cans of crushed tomatoes')

        expect(result).to eq([
          { name: 'crushed tomatoes', quantity: '2', unit: 'can' }
        ])
      end

      it 'parses complex input with multiple items' do
        response_body = {
          content: [
            {
              text: '[{"name": "red onion", "quantity": "2", "unit": "whole"}, {"name": "garlic", "quantity": "5", "unit": "cloves"}, {"name": "spinach", "quantity": "1", "unit": "bag"}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('2 red onions, 5 cloves of garlic, and a bag of spinach')

        expect(result).to eq([
          { name: 'red onion', quantity: '2', unit: 'whole' },
          { name: 'garlic', quantity: '5', unit: 'cloves' },
          { name: 'spinach', quantity: '1', unit: 'bag' }
        ])
      end

      it 'handles JSON wrapped in markdown code blocks' do
        response_body = {
          content: [
            {
              text: "```json\n[{\"name\": \"tomatoes\", \"quantity\": \"3\", \"unit\": \"whole\"}]\n```"
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('three tomatoes')

        expect(result).to eq([
          { name: 'tomatoes', quantity: '3', unit: 'whole' }
        ])
      end

      it 'handles empty input with empty array response' do
        response_body = {
          content: [
            {
              text: '[]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('')

        expect(result).to eq([])
      end

      it 'sends correct API request format' do
        response_body = {
          content: [
            {
              text: '[]'
            }
          ]
        }.to_json

        request_stub = stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'x-api-key' => api_key,
              'anthropic-version' => '2023-06-01'
            }
          )
          .to_return(status: 200, body: response_body)

        described_class.parse('test input')

        expect(request_stub).to have_been_requested
      end

      it 'includes input text in the prompt' do
        response_body = {
          content: [
            {
              text: '[]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        described_class.parse('my test input')

        expect(
          a_request(:post, 'https://api.anthropic.com/v1/messages').with { |req|
            body = JSON.parse(req.body)
            body['messages'][0]['content'].include?('my test input')
          }
        ).to have_been_made.once
      end
    end

    context 'with API errors' do
      it 'raises APIError on 401 unauthorized' do
        error_body = {
          error: {
            message: 'Invalid API key'
          }
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 401, body: error_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::APIError,
          /Invalid API key/
        )
      end

      it 'raises APIError on 429 rate limit' do
        error_body = {
          error: {
            message: 'Rate limit exceeded'
          }
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 429, body: error_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::APIError,
          /Rate limit exceeded/
        )
      end

      it 'raises APIError on timeout' do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_timeout

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::APIError,
          /timed out/
        )
      end

      it 'raises APIError on network error' do
        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_raise(SocketError.new('Connection failed'))

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::APIError,
          /Connection failed/
        )
      end
    end

    context 'with malformed API responses' do
      it 'raises ParseError when content is missing' do
        response_body = {
          something: 'else'
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::ParseError,
          /Unexpected API response format/
        )
      end

      it 'raises ParseError when JSON is invalid' do
        response_body = {
          content: [
            {
              text: 'not valid json'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::ParseError,
          /Failed to parse API response as JSON/
        )
      end

      it 'raises ParseError when response is not an array' do
        response_body = {
          content: [
            {
              text: '{"name": "item", "quantity": "1", "unit": "whole"}'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::ParseError,
          /Expected JSON array/
        )
      end

      it 'raises ParseError when item is missing required fields' do
        response_body = {
          content: [
            {
              text: '[{"name": "item"}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        expect {
          described_class.parse('test')
        }.to raise_error(
          PantryManager::NaturalLanguageParser::ParseError,
          /Invalid item format/
        )
      end
    end

    context 'edge cases' do
      it 'strips whitespace from item fields' do
        response_body = {
          content: [
            {
              text: '[{"name": "  tomatoes  ", "quantity": " 3 ", "unit": " whole "}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('test')

        expect(result).to eq([
          { name: 'tomatoes', quantity: '3', unit: 'whole' }
        ])
      end

      it 'converts all field values to strings' do
        response_body = {
          content: [
            {
              text: '[{"name": "tomatoes", "quantity": 3, "unit": "whole"}]'
            }
          ]
        }.to_json

        stub_request(:post, 'https://api.anthropic.com/v1/messages')
          .to_return(status: 200, body: response_body)

        result = described_class.parse('test')

        expect(result).to eq([
          { name: 'tomatoes', quantity: '3', unit: 'whole' }
        ])
      end
    end
  end
end
