# Replace dry_schema_json with JSON Schema Hash Literals

Replace `dry_schema_json` helper usage with JSON schema-compliant hash literals following our schema-based validation approach.

## Prerequisites

- Review `docs/schemas.md` for JSON schema guidelines
- Review `docs/controllers.md` for controller conventions

## Understanding dry_schema_json

The `dry_schema_json` helper is defined in `app/schemas/api/v1/shared.rb`:

```ruby
# @deprecated dry_schema doesn't support all the typing functionality. Use regular hash instead.
def dry_schema_json(&)
  Dry::Schema.JSON(&).json_schema.excluding(:$schema)
end
```

**What it does:**

- Takes a block containing dry-schema DSL
- Converts it to a JSON schema hash using `Dry::Schema.JSON`
- Removes the `$schema` key from the output

**Where it's used:**

- Schema files in `app/schemas/` directory
- Methods that define request or response schemas

**Why replace:**

- Marked as deprecated in code comments
- Hash literals provide better control and consistency
- Aligns with our existing JSON schema patterns
- Removes dependency on dry-schema gem extensions

## Mass Assignment Protection with additionalProperties: false

For create and update request schemas, **always use `additionalProperties: false`** to prevent malicious parameters and protect against mass assignment vulnerabilities.

### When to Use additionalProperties: false

Use `additionalProperties: false` on:
- **POST actions (create)** - Prevents unexpected properties in create requests
- **PATCH actions (update)** - Prevents unexpected properties in update requests  
- **Nested objects** within create/update requests - Prevents unexpected nested properties

### Why This Matters

- **Security**: Prevents users from submitting unexpected fields that could modify sensitive data
- **Mass Assignment Protection**: Since JSON schema validation replaces strong params filtering, this ensures only allowlisted parameters are accepted
- **Data Integrity**: Ensures only intended fields can be modified through the API

### Examples

**✅ DO: Use additionalProperties: false for create/update schemas**

```ruby
def create_request_schema
  {
    type: :object,
    required: %w[data],
    properties: {
      data: {
        type: :object,
        required: %w[attributes],
        properties: {
          attributes: {
            type: :object,
            required: %w[name email],
            properties: {
              name: { type: :string },
              email: { type: :string },
              bio: { type: :string }
            },
            additionalProperties: false  # Prevent unexpected attributes
          }
        },
        additionalProperties: false  # Prevent unexpected data properties
      }
    },
    additionalProperties: false  # Prevent unexpected root properties
  }
end
```

**❌ DON'T: Omit additionalProperties: false on create/update schemas**

```ruby
def create_request_schema
  {
    type: :object,
    properties: {
      data: {
        type: :object,
        properties: {
          attributes: {
            type: :object,
            properties: {
              name: { type: :string },
              email: { type: :string }
            }
            # ❌ Missing additionalProperties: false - allows any extra fields!
          }
        }
        # ❌ Missing additionalProperties: false
      }
    }
    # ❌ Missing additionalProperties: false
  }
end
```

**✅ OK: Don't use additionalProperties: false for response schemas**

```ruby
def show_response_schema
  {
    type: :object,
    properties: {
      data: {
        type: :object,
        properties: {
          id: { type: :string },
          attributes: {
            type: :object,
            properties: {
              name: { type: :string },
              email: { type: :string }
            }
            # No additionalProperties: false needed for responses
          }
        }
      }
    }
  }
end
```

## Dry-Schema DSL to JSON Schema Mapping

| Dry-Schema DSL                                               | JSON Schema Hash                                     |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| `required(:field).filled(:string)`                           | `field: { type: :string }` in `required: ['field']`  |
| `optional(:field).maybe(:string)`                            | `field: { type: [:string, :null] }`                  |
| `required(:field).filled(:integer)`                          | `field: { type: :integer }` in `required: ['field']` |
| `required(:field).filled(:bool)`                             | `field: { type: :boolean }` in `required: ['field']` |
| `required(:field).array(:string)`                            | `field: { type: :array, items: { type: :string } }`  |
| `required(:field).hash do ... end`                           | Nested `properties: { ... }` structure               |
| `required(:field).filled(:string, included_in?: ['a', 'b'])` | `field: { type: :string, enum: ['a', 'b'] }`         |

## Migration Steps

### Step 1: Get Hash Output from Existing Method

Call the schema method in Rails console to get the JSON schema hash:

```ruby
# In Rails console (rails console or bin/rails console)
require './config/environment'

# Example: Get the hash output
schema = API::V1::OrganizationMembersSchemas.update_request_schema
puts schema.inspect
# or
puts JSON.pretty_generate(schema)
```

This will output the JSON schema hash that dry-schema generates. You can use this as a reference or starting point for the hash literal.

### Step 2: Replace dry_schema_json Block with Hash Literal

Replace the `dry_schema_json` block with a hash literal. The hash should match the output from Step 1.

**Before:**

```ruby
def update_request_schema
  dry_schema_json do
    required(:id).filled(:string)
    required(:data).hash do
      required(:attributes).hash do
        required(:roleId).filled(:integer)
      end
    end
  end
end
```

**After:**

```ruby
def update_request_schema
  {
    type: :object,
    required: %w[id data],
    properties: {
      id: { type: :string },
      data: {
        type: :object,
        required: %w[attributes],
        properties: {
          attributes: {
            type: :object,
            required: %w[roleId],
            properties: {
              roleId: { type: :integer },
            },
          },
        },
      },
    },
  }
end
```

### Step 2: Format Hash Using Ruby Hash Literal Syntax

Follow these formatting guidelines:

- Use symbol keys (`:type` not `'type'`) for consistency with existing schemas
- Use `%w[]` for required arrays when appropriate
- Indent nested structures consistently (2 spaces)
- Keep `required` arrays alphabetically sorted when possible
- Use `nullable: true` instead of `type: [:string, :null]` if preferred (check existing patterns)

### Step 3: Generate TypeScript and Swagger Definitions

After making changes to schema files, generate TypeScript types and Swagger documentation:

```bash
# Generate Ruby TypeScript types and Swagger definitions
bin/generate-ruby-ts

# Generate Swagger definitions and TypeScript types
bin/swagger-generate
```

These scripts ensure that:

- TypeScript types are updated from the schema changes
- Swagger/OpenAPI documentation reflects the updated schemas
- API documentation stays in sync with code changes

### Step 4: Find and Run Associated Spec

Find the spec file that uses this schema:

```bash
# Search for the schema method name in specs
grep -r "update_request_schema\|create_response_schema" spec/
```

Run the spec to verify the conversion:

```bash
bundle exec rspec spec/requests/api/v1/organization_members_controller_spec.rb
```

Or run a specific example:

```bash
bundle exec rspec spec/requests/api/v1/organization_members_controller_spec.rb:15
```

**Important:** Always run `bin/generate-ruby-ts` and `bin/swagger-generate` after making changes to `app/schemas` files, and before running specs to ensure everything stays in sync.

## Examples

### Example 1: Simple Request Schema

**Before:**

```ruby
def update_request_schema
  dry_schema_json do
    required(:id).filled(:string)
    required(:data).hash do
      required(:attributes).hash do
        required(:roleId).filled(:integer)
      end
    end
  end
end
```

**After:**

```ruby
def update_request_schema
  {
    type: :object,
    required: %w[id data],
    properties: {
      id: { type: :string },
      data: {
        type: :object,
        required: %w[attributes],
        properties: {
          attributes: {
            type: :object,
            required: %w[roleId],
            properties: {
              roleId: { type: :integer },
            },
          },
        },
      },
    },
  }
end
```

### Example 2: Response Schema with Arrays

**Before:**

```ruby
def response_schema
  dry_schema_json do
    required(:data).array(:hash) do
      required(:id).filled(:string)
      required(:type).filled(:str?, included_in?: ['projectSessionSignupPageSession'])
      required(:attributes).hash do
        required(:attendeeDisplay).value(:string)
        required(:isUnderAttendeeLimit).filled(:bool)
      end
    end
  end
end
```

**After:**

```ruby
def response_schema
  {
    type: :object,
    required: %w[data],
    properties: {
      data: {
        type: :array,
        items: {
          type: :object,
          required: %w[id type attributes],
          properties: {
            id: { type: :string },
            type: { type: :string, enum: ['projectSessionSignupPageSession'] },
            attributes: {
              type: :object,
              required: %w[attendeeDisplay isUnderAttendeeLimit],
              properties: {
                attendeeDisplay: { type: :string },
                isUnderAttendeeLimit: { type: :boolean },
              },
            },
          },
        },
      },
    },
  }
end
```

### Example 3: Optional Fields with Nullable Types

**Before:**

```ruby
dry_schema_json do
  required(:name).filled(:string)
  optional(:description).maybe(:string)
  optional(:compensationAmount).maybe(:string)
end
```

**After:**

```ruby
{
  type: :object,
  required: %w[name],
  properties: {
    name: { type: :string },
    description: { type: [:string, :null] },
    compensationAmount: { type: [:string, :null] },
  },
}
```

Or using `nullable: true` (check existing patterns in your codebase):

```ruby
{
  type: :object,
  required: %w[name],
  properties: {
    name: { type: :string },
    description: { type: :string, nullable: true },
    compensationAmount: { type: :string, nullable: true },
  },
}
```

### Example 4: Nested Hash Structures

**Before:**

```ruby
dry_schema_json do
  required(:data).hash do
    required(:attributes).hash do
      required(:settings).hash do
        required(:enabled).filled(:bool)
      end
      required(:meta).hash do
        required(:canView).filled(:bool)
      end
    end
  end
end
```

**After:**

```ruby
{
  type: :object,
  required: %w[data],
  properties: {
    data: {
      type: :object,
      required: %w[attributes],
      properties: {
        attributes: {
          type: :object,
          required: %w[settings meta],
          properties: {
            settings: {
              type: :object,
              required: %w[enabled],
              properties: {
                enabled: { type: :boolean },
              },
            },
            meta: {
              type: :object,
              required: %w[canView],
              properties: {
                canView: { type: :boolean },
              },
            },
          },
        },
      },
    },
  },
}
```

## Common Patterns

### Required String Fields

**Dry-Schema:**

```ruby
required(:name).filled(:string)
```

**JSON Schema:**

```ruby
name: { type: :string }
# Include 'name' in required: %w[name]
```

### Optional Nullable Fields

**Dry-Schema:**

```ruby
optional(:description).maybe(:string)
```

**JSON Schema:**

```ruby
description: { type: [:string, :null] }
# or
description: { type: :string, nullable: true }
```

### Enums

**Dry-Schema:**

```ruby
required(:status).filled(:string, included_in?: ['active', 'inactive'])
```

**JSON Schema:**

```ruby
status: { type: :string, enum: ['active', 'inactive'] }
```

### Arrays

**Dry-Schema:**

```ruby
required(:tags).array(:string)
```

**JSON Schema:**

```ruby
tags: {
  type: :array,
  items: { type: :string },
}
```

### Arrays of Objects

**Dry-Schema:**

```ruby
required(:items).array(:hash) do
  required(:id).filled(:string)
  required(:name).filled(:string)
end
```

**JSON Schema:**

```ruby
items: {
  type: :array,
  items: {
    type: :object,
    required: %w[id name],
    properties: {
      id: { type: :string },
      name: { type: :string },
    },
  },
}
```

### Empty Hash Objects

**Dry-Schema:**

```ruby
required(:settings).hash do
end
```

**JSON Schema:**

```ruby
settings: {
  type: :object,
  properties: {},
}
```

## Verification

### Finding Associated Specs

Search for the schema method name in spec files:

```bash
# Find specs using a specific schema method
grep -r "update_request_schema" spec/
```

Common locations:

- `spec/requests/api/v1/*_controller_spec.rb` - Request specs
- `spec/support/rswag/requests/*.rb` - RSwag documentation helpers

### Running Specs

**Important:** Before running specs, ensure you've generated TypeScript types and Swagger definitions:

```bash
# Generate TypeScript and Swagger definitions first
bin/generate-ruby-ts
bin/swagger-generate
```

Then run the full spec file:

```bash
bundle exec rspec spec/requests/api/v1/organization_members_controller_spec.rb
```

Or run a specific line:

```bash
bundle exec rspec spec/requests/api/v1/organization_members_controller_spec.rb:15
```

**Note:** Always run `bin/generate-ruby-ts` and `bin/swagger-generate` after every change to `app/schemas` files to keep TypeScript types and API documentation in sync.

### Verifying Schema Still Works

1. **In Controller Tests:**
   - Ensure `validate_params` calls still work
   - Verify validation errors are raised correctly

2. **In Request Specs:**
   - Check that RSwag schema references still work
   - Verify API documentation generates correctly

3. **In Rails Console:**
   - Call the schema method and verify it returns a hash
   - Check that the hash structure matches expectations

4. **In Browser**
  - Find where the API endpoint is called in the app
  - Use the browser to navigate to a page that allows calling that API endpoint
  - Use the browser to initiate an action that will result in calling that API endpoint
  - Verify from the Network tab that the request is made correctly (200)

## Troubleshooting

### Issue: Schema validation fails after conversion

**Solution:**

- Compare the hash output from `dry_schema_json` (via Rails console) with your hash literal
- Check for differences in `type` values (symbols vs strings)
- Verify `required` arrays include all required fields
- Ensure nested structures match exactly

### Issue: Spec fails with schema validation errors

**Solution:**

- Run the spec with detailed output: `bundle exec rspec spec/path/to/file_spec.rb --format documentation`
- Check that the schema method returns the expected structure
- Verify that controller `validate_params` calls use the correct schema

### Issue: Type mismatches (symbols vs strings)

**Solution:**

- Dry-schema may output `type: 'string'` (string) while existing schemas use `type: :string` (symbol)
- Check existing schemas in the same file to match the pattern
- Generally, use symbols (`:string`, `:object`, etc.) for consistency

## Reference

- `docs/schemas.md` - JSON schema guidelines and examples
- `app/schemas/api/v1/organization_members_schemas.rb` - Example file with both patterns (see `update_request_schema` vs `member_response_schema`)
- `app/schemas/api/v1/shared.rb` - Defines `dry_schema_json` helper

## Verification Checklist

- [ ] Hash output retrieved from Rails console
- [ ] `dry_schema_json` block replaced with hash literal
- [ ] Hash formatted using Ruby hash literal syntax
- [ ] Ran `bin/generate-ruby-ts` to regenerate TypeScript types
- [ ] Ran `bin/swagger-generate` to regenerate Swagger definitions
- [ ] Associated spec file found and run
- [ ] All tests pass
- [ ] Schema method returns correct hash structure
- [ ] Controller validation still works
- [ ] RSwag documentation generates correctly
- [ ] TypeScript types updated correctly
