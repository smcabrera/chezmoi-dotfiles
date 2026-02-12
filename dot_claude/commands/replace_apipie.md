# Replace Apipie with JSON Schema Validation

Replace apipie DSL usage with JSON schema validation following our schema-based validation approach.

## Prerequisites

- Review `docs/schemas.md` for JSON schema guidelines
- Review `docs/controllers.md` for controller conventions
- Identify the controller/concern to migrate using `bin/find-apipie-usage`

## Apipie DSL Reference

### Common DSL Methods

**`api`** - Endpoint Documentation
```ruby
api :GET, '/accounts/:id', 'Get account information'
api :POST, '/accounts', 'Create a new account'
```

**`param`** - Parameter Definition
```ruby
param :id, :number, required: true
param :email, String, required: false, desc: 'Email address'
param :name, String, allow_blank: true, allow_nil: true
```

**Common Parameter Types:**
- `:number` / `:integer` - Numeric values
- `String` - String values
- `Hash` - Hash/nested objects
- `Array` - Array values
- `:boolean` - Boolean values
- `[true, false]` - Enum-like boolean arrays

**Common Options:**
- `required: true/false` - Whether parameter is required
- `allow_blank: true/false` - Allow blank strings
- `allow_nil: true/false` - Allow nil values
- `desc: 'description'` - Parameter description
- `of: Type` - For array parameters, specifies element type

**`param_group`** - Reusable Parameter Groups
```ruby
param_group :pagination, API::Pageable
param_group :sorting, API::Sortable
```

**`def_param_group`** - Define Parameter Groups (in concerns)
```ruby
def_param_group :pagination do
  param :page, Hash, desc: 'Pagination status' do
    param :number, :number
    param :size, :number
  end
end
```

**JSON API Helpers:**
- `json_api_attributes_params` - Documents `data.attributes.*`
- `json_api_filter_params` - Documents `filter.*`
- `json_api_relationships_params` - Documents `data.relationships.*`
- `json_api_fields_params` - Documents `fields.*`

**Concern Extensions:**
```ruby
module API
  module Pageable
    extend Apipie::DSL::Concern
    # ...
  end
end
```

**Error Handling:**
```ruby
rescue_from Apipie::ParamError do |e|
  respond_with_errors(e)
end
```

## Apipie to JSON Schema Mapping

| Apipie | JSON Schema |
|--------|------------|
| `api :GET, '/path'` | Endpoint documented in routes/swagger (not in schema) |
| `param :id, :number, required: true` | `id: { type: 'string' }` in `required: ['id']` (IDs are strings) |
| `param :name, String, allow_blank: false` | `name: { type: 'string', minLength: 1 }` |
| `param :email, String, allow_nil: true` | `email: { type: ['string', 'null'] }` |
| `param :tags, Array, of: String` | `tags: { type: 'array', items: { type: 'string' } }` |
| `param :meta, Hash` | `meta: { type: 'object', properties: { ... } }` |
| `json_api_attributes_params` | `data: { type: 'object', properties: { attributes: { ... } } }` |
| `param_group :pagination` | Inline schema properties or shared schema definitions |

**Important Note:** IDs are normally represented as strings in JSON Schema even if apipie documents them as `:number` or `:integer`. This is because Rails params convert path parameters to strings, and our API consistently treats IDs as string values.

**ID Schema Helper:** Use the `primary_key_schema` method when defining ID parameters in request schemas to ensure consistent ID validation across the API:

```ruby
properties: {
  id: primary_key_schema,
  project_id: primary_key_schema
}
```

**Security Note:** For POST and PATCH actions (create/update), always use `additionalProperties: false` on the main request object and nested objects to prevent malicious parameters. Since we're replacing strong params with JSON schema validation, this ensures only allowlisted parameters are accepted.

## Migration Steps

### Step 1: Identify Apipie Patterns

Examine the controller or concern file and identify:
- `api :METHOD, '/path'` declarations
- `param :name, Type, options` definitions
- `param_group :name, Concern` references
- `json_api_*_params` helper blocks
- `def_param_group` definitions (in concerns)
- `extend Apipie::DSL::Concern` (in concerns)
- `rescue_from Apipie::ParamError` handlers

### Step 2: Create JSON Schema File

Create the schema file following the controller namespace structure:

- Controller: `app/controllers/api/v1/projects/custom_emails_controller.rb`
- Schema: `app/schemas/api/v1/projects/custom_emails_schemas.rb`

Schema file structure:
```ruby
# frozen_string_literal: true

module API
  module V1
    module Projects
      module CustomEmailsSchemas
        def show_request_schema
          {
            type: 'object',
            properties: {
              id: primary_key_schema,  # Use primary_key_schema for IDs
              # ... other properties
            },
            required: ['id']
          }
        end

        def create_request_schema
          {
            type: 'object',
            properties: {
              # ... properties
            },
            required: ['data'],
            additionalProperties: false  # Security: prevent unexpected parameters
          }
        end

        def show_response_schema
          {
            type: 'object',
            properties: {
              data: {
                # ... JSON API response structure
              }
            },
            required: ['data']
          }
        end
      end
    end
  end
end
```

### Step 3: Convert Parameters to JSON Schema

Map apipie parameters to JSON schema properties:

#### Simple Parameters

**Apipie:**
```ruby
param :id, :number, required: true
param :include, String, required: false
```

**JSON Schema:**
```ruby
properties: {
  id: primary_key_schema,  # Use primary_key_schema for IDs
  include: { type: 'string' }
},
required: ['id']
```

#### String Parameters

**Apipie:**
```ruby
param :name, String, allow_blank: false
param :email, String, allow_nil: true
param :description, String, allow_blank: true
```

**JSON Schema:**
```ruby
properties: {
  name: { type: 'string', minLength: 1 },
  email: { type: ['string', 'null'] },
  description: { type: 'string' }
}
```

#### Array Parameters

**Apipie:**
```ruby
param :ids, Array, of: :number
```

**JSON Schema:**
```ruby
properties: {
  tags: {
    type: 'array',
    items: { type: 'string' }
  },
  ids: {
    type: 'array',
    items: primary_key_schema  # Use primary_key_schema for ID arrays
  }
}
```

#### Hash/Nested Objects

**Apipie:**
```ruby
param :page, Hash do
  param :number, :number
  param :size, :number
end
```

**JSON Schema:**
```ruby
properties: {
  page: {
    type: 'object',
    properties: {
      number: { type: 'integer' },
      size: { type: 'integer' }
    },
    additionalProperties: false  # For POST/PATCH: prevent unexpected nested properties
  }
}
```

#### JSON API Attributes

**Apipie:**
```ruby
json_api_attributes_params do
  param :content, String, required: true
  param :subject, String, required: true
end
```

**JSON Schema:**
```ruby
properties: {
  data: {
    type: 'object',
    properties: {
      attributes: {
        type: 'object',
        properties: {
          content: { type: 'string', minLength: 1 },
          subject: { type: 'string', minLength: 1 }
        },
        required: ['content', 'subject'],
        additionalProperties: false  # Security: prevent unexpected attributes
      }
    },
    required: ['attributes'],
    additionalProperties: false  # Security: prevent unexpected data properties
  }
},
required: ['data'],
additionalProperties: false  # Security: prevent unexpected root properties
```

#### JSON API Filters

**Apipie:**
```ruby
json_api_filter_params do
  param :emailSearch, String, desc: 'An email to search by'
  param :omniSearch, String, desc: 'An omni search term'
end
```

**JSON Schema:**
```ruby
properties: {
  filter: {
    type: 'object',
    properties: {
      emailSearch: { type: 'string' },
      omniSearch: { type: 'string' }
    }
  }
}
```

#### Enum Values

**Apipie:**
```ruby
param :status, %w[active inactive pending]
param :actorType, SUPPORTED_ACTOR_TYPES
```

**JSON Schema:**
```ruby
properties: {
  status: {
    type: 'string',
    enum: %w[active inactive pending]
  },
  actorType: {
    type: 'string',
    enum: %w[Account MixpanelUser Organization Participant Team User]
  }
}
```

#### Boolean Parameters

**Apipie:**
```ruby
param :sendTracking, :boolean, required: false
param :autoLaunchProjects, [true, false], allow_nil: true
```

**JSON Schema:**
```ruby
properties: {
  sendTracking: { type: 'boolean' },
  autoLaunchProjects: { type: ['boolean', 'null'] }
}
```

### Step 4: Update Controller

Replace apipie DSL with `validate_params` calls:

**Before:**
```ruby
api :GET, '/accounts/:id', 'Get account information'
param :id, :number, required: true
param :include, String, 'Optionally include associated resources'
def show
  account = Account.find(params[:id])
  respond_with_resource(account)
end
```

**After:**
```ruby
def show
  validate_params(AccountsSchemas.show_request_schema)
  account = Account.find(params[:id])
  respond_with_resource(account)
end
```

**Remove:**
- All `api :METHOD, '/path', 'description'` lines
- All `param :name, Type, options` lines
- All `param_group :name, Concern` references
- All `json_api_*_params` blocks
- `rescue_from Apipie::ParamError` handlers (if present)

### Step 5: Update Concerns

For concerns that define parameter groups:

**Before:**
```ruby
module API
  module Pageable
    extend Apipie::DSL::Concern

    def_param_group :pagination do
      param :page, Hash, desc: 'Pagination status' do
        param :number, :number
        param :size, :number
      end
    end
  end
end
```

**After:**
Remove the concern's apipie DSL. Parameter groups should be inlined into schemas or defined as shared schema methods.

If pagination is needed, include it directly in the schema:
```ruby
# In the schema file
def index_request_schema
  {
    type: 'object',
    properties: {
      page: {
        type: 'object',
        properties: {
          number: { type: 'integer' },
          size: { type: 'integer' }
        }
      }
    }
  }
end
```

### Step 6: Update Request Specs

Replace apipie-generated documentation with RSwag schema references:

**Before (with apipie):**
```ruby
api :GET, '/accounts/:id', 'Get account information'
param :id, :number, required: true
```

**After (with JSON schema):**
```ruby
path '/api/accounts/{id}' do
  get 'Get account information' do
    parameter name: :id, in: :path, type: :string, required: true

    # For request body validation
    parameter name: :params,
      in: :body,
      required: true,
      schema: API::V1::AccountsSchemas.update_request_schema

    # For response validation
    response '200', 'OK' do
      schema API::V1::AccountsSchemas.show_response_schema
      run_test!
    end
  end
end
```

### Step 7: Handle Path Parameters

Apipie documents path parameters (like `:id` in `/accounts/:id`), but these are typically handled by Rails routing. In JSON schema, include them if they need validation:

```ruby
properties: {
  id: primary_key_schema  # Use primary_key_schema for path parameter IDs
},
required: ['id']
```

### Step 8: Test the Migration

1. Run the controller tests: `bundle exec rspec spec/requests/api/v1/your_controller_spec.rb`
2. Verify request validation works correctly
3. Verify error responses match expected format
4. Check that Swagger documentation generates correctly

## Common Patterns

### Pattern 1: Simple GET Endpoint

**Before:**
```ruby
api :GET, '/accounts/:id', 'Get account information'
param :id, :number, required: true
param :include, String, 'Optionally include associated resources'
def show
  # ...
end
```

**After:**
```ruby
# Schema
def show_request_schema
  {
    type: 'object',
    properties: {
      id: primary_key_schema,  # Use primary_key_schema for IDs
      include: { type: 'string' }
    },
    required: ['id']
  }
end

# Controller
def show
  validate_params(AccountsSchemas.show_request_schema)
  # ...
end
```

### Pattern 2: POST/PATCH with JSON API Attributes

**Before:**
```ruby
api :PATCH, '/custom-emails/:id', "Update a set's email"
json_api_attributes_params do
  param :content, String, required: true
  param :subject, String, required: true
end
def update
  # ...
end
```

**After:**
```ruby
# Schema
def update_request_schema
  {
    type: 'object',
    properties: {
      data: {
        type: 'object',
        properties: {
          attributes: {
            type: 'object',
            properties: {
              content: { type: 'string', minLength: 1 },
              subject: { type: 'string', minLength: 1 }
            },
            required: ['content', 'subject'],
            additionalProperties: false  # Security: prevent unexpected attributes
          }
        },
        required: ['attributes'],
        additionalProperties: false  # Security: prevent unexpected data properties
      }
    },
    required: ['data'],
    additionalProperties: false  # Security: prevent unexpected root properties
  }
end

# Controller
def update
  validate_params(CustomEmailsSchemas.update_request_schema)
  # ...
end
```

### Pattern 3: Index with Pagination, Filtering, Sorting

**Before:**
```ruby
api :GET, '/accounts', 'Search researcher accounts'
param :include, String, 'Optionally include associated resources'
json_api_filter_params do
  param :emailSearch, String, desc: 'An email to search by'
end
param :sort, String, desc: 'How to sort account results'
param_group :pagination, API::Pageable
def index
  # ...
end
```

**After:**
```ruby
# Schema
def index_request_schema
  {
    type: 'object',
    properties: {
      include: { type: 'string' },
      filter: {
        type: 'object',
        properties: {
          emailSearch: { type: 'string' }
        }
      },
      sort: { type: 'string' },
      page: {
        type: 'object',
        properties: {
          number: { type: 'integer' },
          size: { type: 'integer' }
        }
      }
    }
  }
end

# Controller
def index
  validate_params(AccountsSchemas.index_request_schema)
  # ...
end
```

## Notes

- JSON schema uses snake_case for property names (matches Rails params), but JSON API attributes can use camelCase
- The `validate_params` method automatically handles error responses via `SchemaValidationConcern`
- After validation, use `deserialized_params` instead of `params.permit(...)` as params are already validated
- Parameter groups (`param_group`) should be inlined into schemas rather than referenced
- Concerns that only define parameter groups can be simplified or removed after migration
- Always create both request and response schemas for proper API documentation
- **Security:** Use `additionalProperties: false` on POST/PATCH request schemas to prevent malicious parameters, since JSON schema validation replaces strong params filtering
- **ID Parameters:** Use `primary_key_schema` for any ID fields (like `id`, `project_id`, `user_id`) to ensure consistent validation and proper type handling

## Verification Checklist

- [ ] Schema file created following namespace structure
- [ ] All apipie DSL removed from controller
- [ ] `validate_params` call added to controller action
- [ ] Request schema matches all documented parameters
- [ ] Response schema matches actual response structure
- [ ] Request spec updated to use schema references
- [ ] Tests pass
- [ ] Swagger documentation generates correctly
- [ ] Error handling works (invalid params return 400)
- [ ] Concern apipie DSL removed (if applicable)
