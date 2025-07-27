---
layout: default
title: System Test Helpers
nav_order: 2
parent: Testing
grand_parent: Developers
---

# System Test Helpers

Panda CMS provides special helper methods for system tests to ensure browser stability and reliable test execution across different environments.

## Safe Helpers Overview

The system test helpers automatically route different types of tests to use appropriate interaction methods:

- **Validation Tests**: Use standard Capybara for proper Rails form validation
- **Other Tests**: Use JavaScript-based interactions to prevent browser resets in CI

## Available Helpers

### Form Interaction
- `safe_fill_in(field, with: value)` - Fill form fields safely
- `safe_click_button(button)` - Click buttons with environment-appropriate method
- `safe_select(value, from: field)` - Select from dropdown menus

### Expectations  
- `safe_expect_field(field, **options)` - Assert field presence/values
- `safe_expect_button(button, **options)` - Assert button presence
- `safe_expect_select(field, **options)` - Assert select field presence

### Navigation
- `safe_click_link(link)` - Click links safely
- `safe_find(selector)` - Find elements with error checking

## Automatic Behavior

### Validation Tests
Tests with descriptions containing validation keywords automatically use standard Capybara:

```ruby
it "shows validation errors when title is missing" do
  # Automatically detected as validation test
  safe_fill_in "title", with: ""  # → uses fill_in
  safe_click_button "Save"        # → uses click_button
end
```

### Non-Validation Tests  
Other tests use JavaScript-based interactions in CI environments:

```ruby
it "creates a new post successfully" do
  # Automatically uses safe helpers
  safe_fill_in "title", with: "Post"  # → uses JavaScript in CI
  safe_click_button "Save"            # → uses click_button
end
```

## Usage Guidelines

1. **Always use safe helpers** in system tests unless you have a specific reason not to
2. **Validation tests** should follow the [validation testing guide](validation-testing.md)
3. **Debug helpers** are available for troubleshooting JavaScript loading issues

## Debugging

If tests are failing, you can use these debug methods:

```ruby
# Check asset loading state
debug_asset_state

# Wait for JavaScript assets to load
wait_for_panda_cms_assets

# Wait for specific elements with asset consideration
wait_for_element_with_assets("selector")
```

See [JavaScript troubleshooting guide](../../TROUBLESHOOTING_JAVASCRIPT.md) for detailed debugging information.