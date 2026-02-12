# Framework Parsing Patterns

Detailed patterns for extracting test failures from CI logs.

## Priority Frameworks

### RSpec (Ruby)

**Detection markers:**
- `rspec ./spec/` in command
- `Failures:` section header
- `Finished in X seconds`
- `.rb:` with line numbers

**Failure pattern:**
```
Failures:

  1) User validates email format
     Failure/Error: expect(user).to be_valid

       expected `#<User id: nil, email: "invalid">.valid?` to be truthy, got false
     # ./spec/models/user_spec.rb:45:in `block (2 levels) in <top (required)>'
```

**Regex patterns:**
```ruby
# File:line extraction
/# \.\/([^\s:]+):(\d+)/

# Test description
/^\s+\d+\) (.+)$/

# Failure section
/^Failures:\n(.*?)(?=^Finished|^$)/m
```

**Local command:**
```bash
bundle exec rspec spec/models/user_spec.rb:45 spec/models/user_spec.rb:67
```

---

### Jest (JavaScript/TypeScript)

**Detection markers:**
- `FAIL` with `.test.ts`, `.test.js`, `.spec.ts`, `.spec.js`
- `✕` for failed tests
- `jest` in output or command
- `Test Suites:` summary

**Failure pattern:**
```
FAIL src/components/Button.test.tsx
  ● Button › renders correctly

    expect(received).toBe(expected)

    Expected: "Submit"
    Received: "Cancel"

      45 |     render(<Button label="Submit" />);
      46 |     expect(screen.getByRole('button')).toHaveTextContent('Submit');
    > 47 |     expect(button.textContent).toBe('Submit');
         |                                ^
      48 |   });

      at Object.<anonymous> (src/components/Button.test.tsx:47:32)
```

**Regex patterns:**
```javascript
// File extraction
/^FAIL\s+(\S+\.(?:test|spec)\.[jt]sx?)$/m

// Test name (suite › test)
/●\s+(.+?)\s+›\s+(.+)$/m

// Line number from stack
/at.*\(([^:]+):(\d+):\d+\)/
```

**Local command:**
```bash
# Run specific file
yarn jest src/components/Button.test.tsx

# Run specific test by name
yarn jest src/components/Button.test.tsx -t "renders correctly"

# Run with pattern
yarn jest --testNamePattern "Button.*renders"
```

---

### Vitest (JavaScript/TypeScript)

**Detection markers:**
- `FAIL` with test file paths
- `⎯⎯⎯ Failed Tests` section
- `vitest` in command or output
- `❯` for test hierarchy

**Failure pattern:**
```
 FAIL  src/utils/format.test.ts > formatCurrency > handles negative values
AssertionError: expected '-$100.00' to be '$-100.00'

 ❯ src/utils/format.test.ts:23:14
     21|   it('handles negative values', () => {
     22|     const result = formatCurrency(-100);
     23|     expect(result).toBe('$-100.00');
       |              ^
     24|   });
```

**Regex patterns:**
```javascript
// Test path extraction
/FAIL\s+(\S+\.test\.[jt]sx?)\s+>\s+(.+)/

// Line from source display
/❯\s+([^:]+):(\d+):\d+/

// Failed tests section
/⎯⎯⎯ Failed Tests ⎯⎯⎯(.*?)(?=⎯⎯⎯|$)/s
```

**Local command:**
```bash
# Run specific file
yarn vitest src/utils/format.test.ts

# Run specific test
yarn vitest src/utils/format.test.ts -t "handles negative values"

# Run in watch mode
yarn vitest src/utils/format.test.ts --watch
```

---

## Secondary Frameworks

### pytest (Python)

**Detection markers:**
- `FAILED test_` or `FAILED tests/`
- `pytest` in command
- `::` separating file/class/method
- `=== FAILURES ===` section

**Failure pattern:**
```
=================================== FAILURES ===================================
_________________________ TestUser.test_email_validation _______________________

self = <tests.test_user.TestUser object at 0x...>

    def test_email_validation(self):
        user = User(email='invalid')
>       assert user.is_valid()
E       AssertionError: assert False

tests/test_user.py:45: AssertionError
```

**Regex patterns:**
```python
# Test identifier
/FAILED\s+([\w\/]+\.py)::(\w+)(?:::(\w+))?/

# File:line from assertion
/(tests?\/[\w\/]+\.py):(\d+):/
```

**Local command:**
```bash
# Run specific test
pytest tests/test_user.py::TestUser::test_email_validation -v

# Run file
pytest tests/test_user.py -v

# Run with keyword
pytest -k "email_validation" -v
```

---

### Go Testing

**Detection markers:**
- `--- FAIL: Test`
- `_test.go:` line references
- `FAIL	package/path`
- `go test` in command

**Failure pattern:**
```
--- FAIL: TestUserValidation (0.00s)
    user_test.go:45: expected valid email, got invalid
        Error: validation failed
FAIL
FAIL	github.com/org/repo/pkg/user	0.123s
```

**Regex patterns:**
```go
// Test name
/--- FAIL: (\w+)/

// File:line
/(\w+_test\.go):(\d+):/

// Package
/FAIL\t([\w\/\.\-]+)\t/
```

**Local command:**
```bash
# Run specific test
go test -run TestUserValidation ./pkg/user

# Run with verbose
go test -v -run TestUserValidation ./pkg/user

# Run all tests in package
go test -v ./pkg/user
```

---

### Minitest (Ruby)

**Detection markers:**
- `Failure:` or `Error:`
- `test_` method names
- `_test.rb` or `test/` paths
- `Minitest` in output

**Failure pattern:**
```
Failure:
UserTest#test_email_validation [test/models/user_test.rb:45]:
Expected: true
  Actual: false
```

**Regex patterns:**
```ruby
# Test identifier
/(\w+)#(test_\w+)\s+\[([^\]]+):(\d+)\]/

# File path
/\[(test\/[^\]]+):(\d+)\]/
```

**Local command:**
```bash
# Run specific test
ruby -Itest test/models/user_test.rb --name test_email_validation

# Run file
ruby -Itest test/models/user_test.rb

# With rails
bin/rails test test/models/user_test.rb:45
```

---

### Mocha (JavaScript)

**Detection markers:**
- `✖` or `failing` count
- `AssertionError` in output
- `mocha` in command
- `describe`/`it` structure in errors

**Failure pattern:**
```
  1) User
       validates email:
     AssertionError: expected false to be true
      at Context.<anonymous> (test/user.test.js:45:14)
```

**Regex patterns:**
```javascript
// Test hierarchy
/^\s+\d+\)\s+(\S+)\n\s+(.+):/m

// File:line
/at.*\(([^:]+):(\d+):\d+\)/
```

**Local command:**
```bash
# Run specific file
yarn mocha test/user.test.js

# Run with grep
yarn mocha --grep "validates email"
```

---

## Multi-Framework Detection

When logs contain multiple frameworks (e.g., Ruby + JS in same CI):

1. Look for workflow/job names to identify context
2. Parse each framework's section separately
3. Group output by framework

```markdown
### RSpec Failures (Ruby)
...

### Jest Failures (JavaScript)
...
```

## Common Log Artifacts

Filter out noise:
- ANSI color codes: `/\x1b\[[0-9;]*m/g`
- Timestamps: `/^\d{4}-\d{2}-\d{2}T[\d:]+Z/`
- GitHub Actions prefixes: `/^##\[.+\]/`
- Progress indicators: `/^\.+$/`
