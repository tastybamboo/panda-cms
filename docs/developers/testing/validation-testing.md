---
layout: default
title: Validation Testing
nav_order: 1
parent: Testing
grand_parent: Developers
---

# Validation Testing

This guide documents best practices for writing reliable validation tests in the Panda CMS system test suite.

## Overview

The system includes automatic validation test detection that routes validation tests to use standard Capybara form interactions instead of safe helpers. This ensures proper Rails validation behavior while maintaining browser stability for other tests.

## Validation Test Detection

Tests are automatically detected as validation tests if their description includes any of these patterns:

```ruby
validation_patterns = [
  'validation',       # "shows validation errors"
  'validates',        # "validates required fields"
  'invalid',          # "with invalid details"
  'required',         # "with required fields", "missing required"
  'missing',          # "when title is missing", "with missing URL"
  'blank',            # "can't be blank"
  'incorrect',        # "with an incorrect URL"
  'already been',     # "URL that has already been used"
  'must start',       # "must start with a forward slash"
  'error.*when',      # "error when adding"
  'fail.*submit'      # "form submission fails"
]
```

## Writing Validation Tests

### ✅ Required Pattern

All validation tests MUST follow this pattern:

```ruby
it "shows validation errors when [field] is missing" do
  # 1. ALWAYS start with clean page state
  visit "/admin/posts/new"  # or appropriate form URL
  
  # 2. Wait for form to be fully loaded
  expect(page).to have_css("form", wait: 5)
  
  # 3. Use safe helpers for form interaction
  safe_fill_in "valid_field", with: "value"
  # Don't fill in the field being tested
  
  # 4. Submit form
  safe_click_button "Create Post"  # or appropriate button
  
  # 5. Check for validation error
  expect(page.html).to include("Field can't be blank")
end
```

### 🔧 Critical Requirements

1. **Clean State**: Every validation test MUST start with `visit` to ensure clean page state
2. **Form Wait**: Include `expect(page).to have_css("form", wait: 5)` to ensure form is loaded
3. **Correct Error Messages**: Use the exact validation error text from the model
4. **Safe Helpers**: Use `safe_fill_in`, `safe_click_button` etc. (they automatically use standard Capybara for validation tests)

### 📝 Example: Complete Validation Test

```ruby
describe "Post validation" do
  before do
    login_as_admin
    visit "/admin/posts"
    visit "/admin/posts/new"
    expect(page.html).to include("Add Post")
  end

  it "shows validation errors when title is missing" do
    # Clean state - REQUIRED
    visit "/admin/posts/new"
    expect(page).to have_css("form", wait: 5)
    
    # Fill valid fields, omit the one being tested
    safe_fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"
    
    # Submit form
    safe_click_button "Create Post"
    
    # Check for exact validation message
    expect(page.html).to include("Title can't be blank")
  end

  it "shows validation errors when URL is missing" do
    # Clean state - REQUIRED  
    visit "/admin/posts/new"
    expect(page).to have_css("form", wait: 5)
    
    # Fill valid fields, omit the one being tested
    safe_fill_in "post_title", with: "Test Post"
    
    # Submit form
    safe_click_button "Create Post"
    
    # Check for exact validation message (note: it's "URL" not "Slug")
    expect(page.html).to include("URL can't be blank")
  end
end
```

## Common Validation Error Messages

### Post Model
- Title: `"Title can't be blank"`
- Slug: `"URL can't be blank"` (not "Slug can't be blank")

### Page Model  
- Title: `"Title can't be blank"`
- Path: `"Path can't be blank"`

### User Model
- Email: `"Email can't be blank"`
- Name: `"Name can't be blank"`

## Debugging Validation Tests

If validation tests are failing, check:

1. **Test Description**: Ensure it contains a validation pattern keyword
2. **Clean State**: Verify the test starts with `visit` 
3. **Error Message**: Check the exact validation message from the model
4. **Form Loading**: Ensure form wait is included
5. **Field Names**: Verify correct form field IDs/names

### Debug Helper

Add this to temporarily debug validation behavior:

```ruby
puts "[DEBUG] Test detected as validation: #{is_validation_test?(RSpec.current_example.full_description)}"
puts "[DEBUG] Page includes error: #{page.html.include?('your error text')}"
puts "[DEBUG] All validation errors: #{page.all('.bg-red-50').map(&:text)}"
```

## Why This Matters

Validation tests require special handling because:

1. **Form State**: Validation depends on clean form state between tests
2. **JavaScript Timing**: Validation logic may depend on client-side JavaScript being loaded
3. **Rails Integration**: Proper form submission and error display requires standard Capybara behavior
4. **Browser Stability**: Non-validation tests use safe helpers to prevent browser resets in CI

## Automatic Behavior

When a test is detected as a validation test:

- `safe_fill_in` → uses standard `fill_in`
- `safe_click_button` → uses standard `click_button`  
- `safe_expect_field` → uses standard `expect(page).to have_field`

This ensures proper Rails form validation while maintaining browser stability for other tests.