module PantryManager
  class IngredientParser
    # Common units
    UNITS = %w[cup cups tablespoon tablespoons tbsp tsp teaspoon teaspoons
               ounce ounces oz pound pounds lb lbs gram grams g
               kilogram kilograms kg milliliter milliliters ml liter liters l
               whole clove cloves bunch bunches sprig sprigs pinch pinches
               can cans jar jars package packages box boxes]

    FRACTIONS = {
      '1/4' => 0.25, '1/2' => 0.5, '3/4' => 0.75,
      '1/3' => 0.33, '2/3' => 0.67,
      '1/8' => 0.125, '3/8' => 0.375, '5/8' => 0.625, '7/8' => 0.875
    }

    def self.parse(text)
      return { quantity: nil, unit: nil, name: '', original: text } if text.nil? || text.strip.empty?

      # Extract quantity (number or fraction)
      quantity_match = text.match(/^(\d+(?:[\s-]+\d+\/\d+|\.\d+|\/\d+)?)/)
      quantity = quantity_match ? quantity_match[1].strip : nil

      # Extract unit
      unit_pattern = /\b(#{UNITS.join('|')})\b/i
      unit_match = text.match(unit_pattern)
      unit = unit_match ? unit_match[1].downcase : nil

      # Extract ingredient name (after quantity and unit)
      ingredient_name = text.dup
      ingredient_name.sub!(/^(\d+(?:[\s-]+\d+\/\d+|\.\d+|\/\d+)?)/, '') if quantity
      ingredient_name.sub!(unit_pattern, '') if unit
      ingredient_name = ingredient_name.strip.downcase

      # Normalize (remove "diced", "chopped", etc.)
      ingredient_name = normalize_name(ingredient_name)

      {
        quantity: quantity,
        unit: unit,
        name: ingredient_name,
        original: text
      }
    end

    def self.normalize_name(name)
      return '' if name.nil? || name.empty?

      # Remove common preparation terms
      prep_terms = %w[diced chopped minced sliced crushed peeled fresh dried
                      grated shredded whole halved quartered optional
                      finely roughly coarsely thinly thickly small medium large
                      room temperature cold warm hot frozen thawed
                      plus more for serving to taste as needed]

      name = name.split(',').first  # Remove everything after comma
      return '' if name.nil?

      name = name.strip

      # Remove parenthetical notes
      name = name.gsub(/\([^)]*\)/, '').strip

      # Remove preparation terms
      prep_terms.each { |term| name.gsub!(/\b#{term}\b/, '') }

      # Clean up extra whitespace
      name = name.gsub(/\s+/, ' ').strip

      # Remove leading/trailing non-alphanumeric characters
      name = name.gsub(/^[^a-z0-9]+|[^a-z0-9]+$/i, '')

      name || ''
    end
  end
end
