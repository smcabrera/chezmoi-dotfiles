require 'spec_helper'

RSpec.describe PantryManager::IngredientParser do
  describe '.parse' do
    context 'with basic quantity and unit' do
      it 'parses fractional quantities' do
        result = described_class.parse("1/4 cup red onion, diced")
        expect(result[:quantity]).to eq('1/4')
        expect(result[:unit]).to eq('cup')
        expect(result[:name]).to eq('red onion')
      end

      it 'parses whole numbers' do
        result = described_class.parse("2 tablespoons olive oil")
        expect(result[:quantity]).to eq('2')
        expect(result[:unit]).to eq('tablespoons')
        expect(result[:name]).to eq('olive oil')
      end

      it 'parses mixed numbers' do
        result = described_class.parse("1 1/2 cups flour")
        expect(result[:quantity]).to eq('1 1/2')
        expect(result[:unit]).to eq('cups')
        expect(result[:name]).to eq('flour')
      end
    end

    context 'with normalization' do
      it 'normalizes "red onions, diced" to "red onions"' do
        result = described_class.parse("2 red onions, diced")
        expect(result[:name]).to eq('red onions')
      end

      it 'normalizes "fresh cilantro, chopped" to "cilantro"' do
        result = described_class.parse("1 bunch fresh cilantro, chopped")
        expect(result[:name]).to eq('cilantro')
      end

      it 'normalizes "garlic, minced" to "garlic"' do
        result = described_class.parse("3 cloves garlic, minced")
        expect(result[:name]).to eq('garlic')
      end

      it 'normalizes "Salt and pepper to taste" to "salt and pepper"' do
        result = described_class.parse("Salt and pepper to taste")
        expect(result[:name]).to eq('salt and pepper')
      end
    end

    context 'with preparation terms' do
      it 'removes "diced"' do
        result = described_class.parse("1 onion, diced")
        expect(result[:name]).not_to include('diced')
      end

      it 'removes "chopped"' do
        result = described_class.parse("2 tomatoes, chopped")
        expect(result[:name]).not_to include('chopped')
      end

      it 'removes "minced"' do
        result = described_class.parse("3 cloves garlic, minced")
        expect(result[:name]).not_to include('minced')
      end

      it 'removes "fresh"' do
        result = described_class.parse("1 bunch fresh parsley")
        expect(result[:name]).not_to include('fresh')
      end

      it 'removes multiple preparation terms' do
        result = described_class.parse("1 large onion, finely diced")
        expect(result[:name]).to eq('onion')
      end
    end

    context 'with edge cases' do
      it 'handles nil input' do
        result = described_class.parse(nil)
        expect(result[:quantity]).to be_nil
        expect(result[:unit]).to be_nil
        expect(result[:name]).to eq('')
      end

      it 'handles empty string' do
        result = described_class.parse('')
        expect(result[:quantity]).to be_nil
        expect(result[:unit]).to be_nil
        expect(result[:name]).to eq('')
      end

      it 'handles ingredient without quantity' do
        result = described_class.parse("Salt to taste")
        expect(result[:quantity]).to be_nil
        expect(result[:name]).to include('salt')
      end

      it 'handles ingredient without unit' do
        result = described_class.parse("3 eggs")
        expect(result[:quantity]).to eq('3')
        expect(result[:unit]).to be_nil
        expect(result[:name]).to eq('eggs')
      end
    end

    context 'with various units' do
      it 'recognizes cup/cups' do
        result = described_class.parse("2 cups water")
        expect(result[:unit]).to eq('cups')
      end

      it 'recognizes tablespoon/tablespoons/tbsp' do
        expect(described_class.parse("1 tablespoon oil")[:unit]).to eq('tablespoon')
        expect(described_class.parse("2 tablespoons oil")[:unit]).to eq('tablespoons')
        expect(described_class.parse("1 tbsp oil")[:unit]).to eq('tbsp')
      end

      it 'recognizes teaspoon/teaspoons/tsp' do
        expect(described_class.parse("1 teaspoon salt")[:unit]).to eq('teaspoon')
        expect(described_class.parse("2 tsp salt")[:unit]).to eq('tsp')
      end

      it 'recognizes cloves' do
        result = described_class.parse("3 cloves garlic")
        expect(result[:unit]).to eq('cloves')
      end

      it 'recognizes pound/pounds/lb/lbs' do
        expect(described_class.parse("1 pound beef")[:unit]).to eq('pound')
        expect(described_class.parse("2 lbs chicken")[:unit]).to eq('lbs')
      end

      it 'recognizes can/cans' do
        result = described_class.parse("1 can tomatoes")
        expect(result[:unit]).to eq('can')
      end
    end

    it 'preserves original text' do
      original = "1/4 cup red onion, diced"
      result = described_class.parse(original)
      expect(result[:original]).to eq(original)
    end
  end

  describe '.normalize_name' do
    it 'returns empty string for nil' do
      expect(described_class.normalize_name(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.normalize_name('')).to eq('')
    end

    it 'removes text after comma' do
      expect(described_class.normalize_name('onion, diced')).to eq('onion')
    end

    it 'removes parenthetical notes' do
      expect(described_class.normalize_name('milk (whole)')).to eq('milk')
    end

    it 'removes preparation terms' do
      expect(described_class.normalize_name('garlic minced')).to eq('garlic')
    end

    it 'cleans up extra whitespace' do
      expect(described_class.normalize_name('  red   onion  ')).to eq('red onion')
    end

    it 'removes leading/trailing non-alphanumeric characters' do
      expect(described_class.normalize_name('- onion -')).to eq('onion')
    end
  end
end
