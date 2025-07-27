---
layout: default
title: Test Flakiness Fix Summary
nav_order: 4
parent: Testing
grand_parent: Developers
---

# Test Flakiness Fix Summary

## Problem

Validation tests for the Post creation form were failing intermittently due to race conditions with JavaScript form submission handling. The tests would sometimes pass and sometimes fail with the error message not appearing in the page HTML.

## Root Cause

The EditorJS form controller intercepts form submissions to save editor content before submitting. This creates a complex async flow:

1. Submit button clicked
2. JavaScript prevents default submission
3. Editor content is saved
4. Form submission is re-triggered

This async handling caused timing issues where validation errors wouldn't appear consistently.

## Solution

Added explicit waits for:
1. **Button enablement**: Wait for EditorJS to initialize and enable the submit button
2. **Error appearance**: Wait for the validation error div to appear after submission

### Code Changes

```ruby
# Before (flaky)
it "shows validation errors when title is missing" do
  visit "/admin/posts/new"
  expect(page).to have_css("form", wait: 5)
  
  safe_fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"
  safe_click_button "Create Post"
  
  expect(page.html).to include("Title can't be blank")
end

# After (reliable)
it "shows validation errors when title is missing" do
  visit "/admin/posts/new"
  expect(page).to have_css("form", wait: 5)
  
  # Wait for EditorJS to initialize and enable the submit button
  expect(page).to have_button("Create Post", disabled: false, wait: 10)
  
  safe_fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"
  safe_click_button "Create Post"
  
  # Wait for validation errors to appear
  expect(page).to have_css('div.bg-red-50', wait: 5)
  
  # Check for exact validation error message
  within('div.bg-red-50') do
    expect(page).to have_content("Title can't be blank")
  end
end
```

## Key Insights

1. **JavaScript initialization timing**: EditorJS disables the submit button until fully initialized
2. **Async form submission**: The custom submit handler creates timing uncertainties
3. **Explicit waits are essential**: Using Capybara's built-in waiting mechanisms solves race conditions
4. **Scope assertions**: Using `within` blocks ensures we're checking the right element

## Verification

- Tests now pass consistently in both local and CI environments
- Ran 10+ consecutive test runs with 0 failures
- Both individual and grouped test runs are reliable

## Documentation Updates

Updated `docs/developers/testing/validation-testing.md` with:
- Required pattern including all wait steps
- Explanation of EditorJS timing issues
- Complete working examples