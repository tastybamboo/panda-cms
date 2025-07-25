---
layout: default
title: Ferrum CSS Selector Issue
nav_order: 5
parent: Testing
grand_parent: Developers
---

# Ferrum CSS Selector Issue

## Problem

When using Capybara with Ferrum driver in system tests, certain CSS selector expectations can cause the browser to navigate to `about:blank`, resulting in test failures with "Could not find node with given id" errors.

## Symptoms

- Test works fine until checking for a CSS selector
- Browser suddenly navigates to `about:blank` 
- Error: `Ferrum::NodeNotFoundError: Could not find node with given id`
- Test screenshots show blank page
- Issue occurs specifically with validation tests checking for error divs

## Root Cause

The issue appears to be related to how Ferrum handles certain DOM queries when the page state changes after form submission. Using `expect(page).to have_css('div.bg-red-50')` can trigger a browser reset.

## Solution

Replace CSS selector expectations with content expectations:

### ❌ Problematic Pattern
```ruby
# This can cause browser to navigate to about:blank
expect(page).to have_css('div.bg-red-50', wait: 5)
within('div.bg-red-50') do
  expect(page).to have_content("Title can't be blank")
end
```

### ✅ Working Pattern
```ruby
# This works reliably
expect(page).to have_content("Title can't be blank", wait: 5)
```

## Applied Fix

All page validation tests were updated to use content expectations instead of CSS selectors:

```ruby
it "shows validation errors with no title" do
  fill_in "page_path", with: "/new-test-page"
  click_button "Create Page"
  
  # Check for validation error directly
  expect(page).to have_content("Title can't be blank", wait: 5)
end
```

## Impact

- Fixed all page validation tests that were failing with `about:blank` navigation
- Tests now run reliably in both local and CI environments
- No functional changes to the application code required

## Verification

Run validation tests to confirm they pass:
```bash
bundle exec rspec spec/system -e "validation"
```

## Notes

- This issue is specific to the Ferrum driver (Chrome headless)
- The safe helper framework was not the cause - standard Capybara methods also triggered the issue
- The issue manifests after form submissions that return validation errors
- Other types of tests (non-validation) may still use CSS selectors without issues