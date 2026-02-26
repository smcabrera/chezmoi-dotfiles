# Natural Language Pantry Add Feature

## Overview

This document describes the natural language parsing feature for the pantry manager CLI, which allows users to add pantry items using conversational input instead of structured arguments.

## Implementation

### Core Components

1. **NaturalLanguageParser** (`lib/natural_language_parser.rb`)
   - Uses the Anthropic API (Claude) to parse natural language input
   - Converts phrases like "four roma tomatoes and a bag of kale" into structured data
   - Returns array of items with `name`, `quantity`, and `unit` fields
   - Handles API errors gracefully with custom error classes

2. **CLI Integration** (`bin/pantry-manager`)
   - Modified `handle_add` method to detect single-argument vs multi-argument input
   - Single argument triggers natural language mode
   - Three or more arguments use structured mode (backward compatible)
   - Two arguments show usage error

3. **Interactive Confirmation Flow**
   - Shows parsed items to user for review
   - Prompts: `Add these items to pantry? [y/n/e(dit)]:`
   - On 'y': adds all items to pantry
   - On 'n': cancels operation
   - On 'e': enters edit mode

4. **Edit-on-Rejection Flow**
   - Allows user to modify each parsed item
   - Can change name, quantity, or unit
   - Can exclude individual items
   - Shows final list for confirmation before adding

### Usage

#### Natural Language Mode

```bash
# Requires ANTHROPIC_API_KEY environment variable
export ANTHROPIC_API_KEY="your-api-key-here"

# Add items using natural language
pantry-manager add "four roma tomatoes and a bag of kale"
pantry-manager add "2 cans of crushed tomatoes"
pantry-manager add "three red onions, 5 cloves of garlic, and a bunch of spinach"
```

#### Structured Mode (Still Works)

```bash
# No API key required
pantry-manager add "red onion" 2 whole
pantry-manager add spinach 1 bag "organic"
```

### Example Session

```
$ pantry-manager add "four roma tomatoes and a bag of kale"

Parsing: four roma tomatoes and a bag of kale

Parsed items:
  1. 4x roma tomatoes (whole)
  2. 1x kale (bag)

Add these items to pantry? [y/n/e(dit)]: y
Added 4 whole roma tomatoes to pantry.
Added 1 bag kale to pantry.
```

### API Integration

The parser uses the Anthropic Messages API:
- **Endpoint**: `https://api.anthropic.com/v1/messages`
- **Model**: `claude-3-haiku-20240307`
- **Authentication**: API key via `x-api-key` header
- **Timeout**: 30 seconds

The prompt is carefully crafted to:
- Extract quantities, units, and item names
- Preserve meaningful units (bag, bunch, container, etc.)
- Convert word numbers to digits ("four" → "4")
- Return JSON array format
- Default to quantity "1" if not specified

### Error Handling

1. **ParseError**
   - Missing API key
   - Invalid JSON response
   - Malformed item structure

2. **APIError**
   - HTTP errors (401, 429, etc.)
   - Network timeouts
   - Connection failures

Errors are displayed to user with helpful messages:
```
Parse error: ANTHROPIC_API_KEY environment variable not set
API error: API request failed (401): Invalid API key
```

## Testing

### Unit Tests

**`spec/natural_language_parser_spec.rb`** (18 examples)
- API key validation
- Successful parsing scenarios
- API error handling
- Malformed response handling
- Edge cases (whitespace, type conversion)

### Integration Tests

**`spec/cli_integration_spec.rb`** (3 examples)
- End-to-end parsing flow
- Database integration
- Backward compatibility with structured mode

### Manual Testing

**`test_natural_language.rb`**
- Requires real API key
- Tests actual API integration
- Multiple test cases

Run with:
```bash
ruby test_natural_language.rb
```

### Test Results

All 189 tests pass:
```
bundle exec rspec
# 189 examples, 0 failures
```

## Files Created/Modified

### New Files
- `lib/natural_language_parser.rb` - Parser implementation
- `spec/natural_language_parser_spec.rb` - Unit tests
- `spec/cli_integration_spec.rb` - Integration tests
- `test_natural_language.rb` - Manual test script
- `NATURAL_LANGUAGE_FEATURE.md` - This document

### Modified Files
- `bin/pantry-manager` - CLI integration and interactive flows
- `README.md` - Updated documentation with examples
- No gem dependencies added (uses Ruby's Net::HTTP)

## Product Spec Compliance

The implementation meets all MVP requirements:

- ✅ Natural language parsing for `pantry add` command
- ✅ Uses LLM (Claude) to parse into structured data
- ✅ Units are tracked and preserved
- ✅ Interactive confirmation with parsed structure
- ✅ Edit capability on rejection
- ✅ Coexistence with structured format
- ✅ Test case verified: `"four roma tomatoes and a bag of kale"`

## Future Enhancements

Potential improvements beyond MVP:
- Support for other LLM providers (OpenAI, local models)
- Caching of parsed results
- Batch import from shopping lists
- Voice input integration
- Learning from user corrections

## Dependencies

- **Runtime**: Ruby standard library (Net::HTTP, JSON)
- **Development**: RSpec, WebMock (already present)
- **External**: Anthropic API (optional, for natural language mode)

No additional gems were required.
