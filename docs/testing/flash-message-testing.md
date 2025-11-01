# Flash Message Testing Guide

This document explains how to test flash messages in Panda CMS, addressing the cross-process timing issues that occur with Capybara system tests.

## The Problem

Flash messages in Rails are designed to persist for exactly one request, then be automatically cleared. In Capybara system tests:

1. Test code triggers action → Flash set → Redirect to page
2. Browser (Cuprite/Selenium) follows redirect in server process
3. Server reads flash to render it → **Flash marked as consumed**
4. Test tries to assert flash content → **Flash already gone**

This is **not** a driver limitation or Redis issue—it's an architectural timing challenge with cross-process testing.

## Solutions

### Solution 1: Request Specs for Flash Testing ✅ RECOMMENDED

Request specs run in-process and can access the `flash` hash directly before it's consumed:

```ruby
# spec/requests/panda/cms/admin/authentication_spec.rb
RSpec.describe "Admin authentication", type: :request do
  it "sets flash alert for non-admin users" do
    post "/admin/test_sessions", params: {user_id: non_admin_user.id}

    # Test flash directly - works in request specs!
    expect(flash[:alert]).to eq("You do not have permission to access the admin area.")
    expect(response).to redirect_to("/admin/login")
  end
end
```

**Benefits:**
- ✅ No timing issues
- ✅ Direct access to controller flash
- ✅ Faster than system tests
- ✅ Tests controller logic, not UI

**Use request specs to test:**
- Flash message content and assignment
- Controller redirects and responses
- Session management
- Authentication flows

### Solution 2: Ensure Views Render Flash

The actual fix for system tests was ensuring layouts render flash messages:

```erb
<!-- app/views/layouts/panda/core/admin_simple.html.erb -->
<%= render "panda/core/shared/header", html_class: "h-full", body_class: "bg-gradient-admin" %>
<%= render "panda/core/admin/shared/flash" %>  <!-- ← MUST BE INCLUDED -->
<div class="flex flex-col items-center justify-center min-h-screen px-4">
  <%= yield %>
</div>
```

### Solution 3: Use flash.keep in Test Environment

For controllers that set flash before redirect, use `flash.keep` to preserve flash across redirects in tests:

```ruby
# app/controllers/panda/cms/admin/test_sessions_controller.rb
def create
  unless user.admin?
    flash[:alert] = "You do not have permission to access the admin area."
    flash.keep(:alert) if Rails.env.test?  # ← Preserve for tests
    redirect_to "/admin/login"
    return
  end
end
```

**Important**: Only use `flash.keep` for explicit flash assignment. When using the redirect shorthand syntax, convert to explicit:

```ruby
# Before (shorthand)
redirect_to admin_login_path, flash: {error: "Message"}

# After (explicit with flash.keep)
flash[:error] = "Message"
flash.keep(:error) if Rails.env.test?
redirect_to admin_login_path
```

### Solution 4: Test Outcomes, Not Flash

For pure system tests, focus on outcomes rather than flash messages:

```ruby
it "prevents non-admin access" do
  login_with_google(regular_user, expect_success: false)

  # Test outcome instead of flash
  expect(page).to have_current_path("/admin/login")
  expect(page).not_to have_content("Dashboard")
  # Optionally test flash if layout renders it
  expect(page).to have_content("You do not have permission")
end
```

## Best Practices

### ✅ DO:
- Use request specs to test flash message content and controller logic
- Use system specs to test user workflows and visual presentation
- Ensure all layouts include flash rendering partials
- Use `flash.keep` in test environment for complex redirect chains
- Test outcomes (redirect paths, page content) rather than flash in system tests

### ❌ DON'T:
- Rely solely on system tests for flash message testing
- Access flash in system tests when request specs would suffice
- Use `flash.keep` in production code (test-only pattern)
- Skip rendering flash in layouts

## Testing Strategy Summary

| What to Test | Test Type | Why |
|-------------|-----------|-----|
| Flash content/assignment | Request Spec | Direct access, no timing issues |
| Controller redirects | Request Spec | Faster, tests logic not UI |
| User workflows | System Spec | Tests full interaction |
| Visual presentation | System Spec | Tests actual user experience |
| JavaScript interactions | System Spec | Requires browser environment |

## Example Test Suite Structure

```
spec/
├── requests/
│   └── panda/
│       └── cms/
│           └── admin/
│               ├── authentication_spec.rb  # Flash content tests
│               └── sessions_spec.rb        # Session management tests
└── system/
    └── panda/
        └── cms/
            └── admin/
                ├── login_spec.rb           # User login workflows
                └── dashboard_spec.rb       # Dashboard interactions
```

## Related Documentation

- [Rails Flash Messages Guide](https://thoughtbot.com/blog/rails-flashes-guide)
- [Request Specs in RSpec](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec)
- [System Tests in Rails](https://guides.rubyonrails.org/testing.html#system-testing)

## Troubleshooting

### Flash messages not appearing in system tests
1. Check layout includes flash rendering partial
2. Verify flash is set before redirect in controller
3. Add `flash.keep` for test environment if needed
4. Consider using request spec instead

### Flash appears but with wrong content
1. Use request spec to test exact content
2. Check controller sets correct flash key (`:alert` vs `:error` vs `:notice`)
3. Verify flash component handles all flash types

### Flash appears on wrong page
1. Check `flash.keep` isn't being called unintentionally
2. Verify redirect chain isn't consuming flash early
3. Consider using `flash.now` for same-request rendering
