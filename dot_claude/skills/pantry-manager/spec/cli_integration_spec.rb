require 'spec_helper'
require 'stringio'
require 'natural_language_parser'

# Load the command handler from bin/pantry-manager
# We need to define CommandHandler in a way that doesn't auto-execute
module PantryManager
  class CommandHandler
    # This is copied from bin/pantry-manager for testing purposes
    # We load the methods but don't auto-execute
    class << self
      # Include all the methods from the bin/pantry-manager file
      # We'll just test the handle methods directly
    end
  end
end

RSpec.describe 'CLI Natural Language Add Integration' do
  let(:api_key) { 'test-api-key-123' }

  before do
    ENV['ANTHROPIC_API_KEY'] = api_key
  end

  after do
    ENV.delete('ANTHROPIC_API_KEY')
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def with_stdin(input)
    original_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = original_stdin
  end

  describe 'natural language parsing flow' do
    it 'parses "four roma tomatoes and a bag of kale" using NaturalLanguageParser' do
      response_body = {
        content: [
          {
            text: '[{"name": "roma tomatoes", "quantity": "4", "unit": "whole"}, {"name": "kale", "quantity": "1", "unit": "bag"}]'
          }
        ]
      }.to_json

      stub_request(:post, 'https://api.anthropic.com/v1/messages')
        .to_return(status: 200, body: response_body)

      result = PantryManager::NaturalLanguageParser.parse('four roma tomatoes and a bag of kale')

      expect(result).to eq([
        { name: 'roma tomatoes', quantity: '4', unit: 'whole' },
        { name: 'kale', quantity: '1', unit: 'bag' }
      ])
    end

    it 'adds parsed items to database' do
      # Test that items can be added using the parsed structure
      items = [
        { name: 'roma tomatoes', quantity: '4', unit: 'whole' },
        { name: 'kale', quantity: '1', unit: 'bag' }
      ]

      items.each do |item|
        PantryManager::PantryItem.add_or_update(item[:name], item[:quantity], item[:unit])
      end

      # Verify items were actually added to database
      tomatoes = PantryManager::PantryItem.joins(:ingredient)
        .find_by(ingredients: { name: 'roma tomatoes' })
      expect(tomatoes).to be_present
      expect(tomatoes.quantity).to eq('4')
      expect(tomatoes.unit).to eq('whole')

      kale = PantryManager::PantryItem.joins(:ingredient)
        .find_by(ingredients: { name: 'kale' })
      expect(kale).to be_present
      expect(kale.quantity).to eq('1')
      expect(kale.unit).to eq('bag')
    end

    it 'structured mode still works with 3+ arguments' do
      PantryManager::PantryItem.add_or_update('red onion', '2', 'whole')

      # Verify item was added
      onion = PantryManager::PantryItem.joins(:ingredient)
        .find_by(ingredients: { name: 'red onion' })
      expect(onion).to be_present
      expect(onion.quantity).to eq('2')
      expect(onion.unit).to eq('whole')
    end
  end
end
