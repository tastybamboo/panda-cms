# Shared System Test Infrastructure

## Overview

Centralized system test infrastructure in `panda-core` to eliminate duplicate configuration across Panda gems and ensure consistent test behavior.

## What Changed

### Panda-Core Changes (Branch: `feat/shared-system-test-infrastructure`)

Created new directory: `lib/panda/core/testing/support/system/`

#### New Files

1. **`cuprite_setup.rb`** - Cuprite driver configuration
   - Registers `:cuprite` driver for desktop testing
   - Registers `:cuprite_mobile` driver for mobile viewport testing (375x667)
   - **CRITICAL**: Sets `js_errors: true` by default (was `false` in panda-cms!)
   - CI-optimized browser options
   - Environment-based configuration (HEADLESS, INSPECTOR, SLOWMO)

2. **`capybara_setup.rb`** - Capybara configuration
   - Default wait times (5s local, 10s CI)
   - Screenshot handling
   - Puma server configuration (single-threaded for shared DB connection)
   - Session tracking for multi-session tests

3. **`system_test_helpers.rb`** - Generic system test helper methods
   - `wait_for_selector`, `wait_for_text`, `wait_for_network_idle`
   - `ensure_page_loaded`, `wait_for_ready_state`
   - `pause`, `browser_debug` for debugging
   - Enhanced screenshot capture on test failures
   - CI-specific error handling

4. **`database_connection_helpers.rb`** - Database connection sharing
   - Allows Puma server to see uncommitted fixture data
   - Moved from panda-cms (was CMS-specific, but actually generic)

### Panda-CMS Changes (Branch: `tests/fix-about-blank-test-failures`)

#### Removed Files (~300 lines)

- `better_rails_system_tests.rb` → now in panda-core `system_test_helpers.rb`
- `capybara_setup.rb` → now in panda-core
- `cuprite_helpers.rb` → now in panda-core `cuprite_setup.rb`
- `cuprite_helper_methods.rb` → now in panda-core `system_test_helpers.rb`
- `database_connection_helpers.rb` → moved to panda-core
- `shared_browser_session.rb` → redundant with panda-core helpers

#### Kept Files (CMS-specific)

- `panda_cms_helpers.rb` - CMS-specific helpers:
  - `wait_for_panda_cms_assets`
  - `safe_*` methods (safe_fill_in, safe_click_button, etc.)
  - `debug_asset_state`
  - `is_validation_test?`
- `authentication_config.rb` - CMS-specific OAuth configuration

#### Fixed ES6 Syntax Issues

All `evaluate_script` and `execute_script` calls now use ES5 syntax:
- Changed `const` → `var` (prevents "SyntaxError: Unexpected token 'const'")
- Affected files:
  - `spec/system/panda/cms/admin/pages/page_form_spec.rb`
  - `spec/system/panda/cms/admin/pages/edit_page_spec.rb`
  - `spec/system/panda/cms/admin/pages/debug_about_blank_spec.rb`

## Key Benefits

### 1. JavaScript Errors Now Reported ✅

**Before**: `js_errors: false` in panda-cms silently swallowed JavaScript errors
**After**: `js_errors: true` in panda-core reports all JavaScript failures

Example of what we now catch:
```
Ferrum::JavaScriptError: SyntaxError: Unexpected token 'var'
```

### 2. Single Source of Truth

All Panda gems now load the same Cuprite/Capybara configuration from panda-core.

### 3. Easy Maintenance

Fix a bug once in panda-core → all gems benefit automatically.

### 4. Consistency

All gems use identical test infrastructure, making behavior predictable.

## How to Use in Other Gems

### Setup (e.g., in panda-community, panda-pro)

1. **Require panda-core testing infrastructure** in `spec/rails_helper.rb`:
   ```ruby
   require "panda/core/testing/rails_helper"
   ```

2. **That's it!** The shared infrastructure auto-loads:
   - Cuprite drivers (`:cuprite` and `:cuprite_mobile`)
   - Capybara configuration
   - Generic system test helpers
   - Database connection sharing

3. **Add gem-specific helpers** in `spec/system/support/`:
   ```ruby
   # spec/system/support/community_helpers.rb
   module CommunityHelpers
     def create_community_post
       # Gem-specific logic
     end
   end

   RSpec.configure do |config|
     config.include CommunityHelpers, type: :system
   end
   ```

### What NOT to Duplicate

❌ Don't create your own Cuprite driver registration
❌ Don't configure Capybara wait times
❌ Don't implement generic helpers like `wait_for_selector`
❌ Don't set up database connection sharing

### What TO Add

✅ Gem-specific helper methods
✅ Gem-specific configuration (e.g., OAuth providers)
✅ Gem-specific Current attributes setup

## Next Steps

### For Panda-Core

1. ✅ Created branch `feat/shared-system-test-infrastructure`
2. ✅ Pushed to GitHub
3. ⏳ **TODO**: Create PR and get review
4. ⏳ **TODO**: Merge to main
5. ⏳ **TODO**: Release panda-core v0.8.1 (or v0.9.0)
6. ⏳ **TODO**: Push gem to RubyGems

### For Panda-CMS

1. ✅ Created branch `tests/fix-about-blank-test-failures`
2. ✅ Removed duplicate files
3. ✅ Fixed ES6 syntax issues
4. ⏳ **TODO**: Wait for panda-core release
5. ⏳ **TODO**: Update Gemfile.lock to use new panda-core
6. ⏳ **TODO**: Test locally with new panda-core
7. ⏳ **TODO**: Create PR

### Testing Locally (Before panda-core is released)

To test with the local panda-core branch:

```bash
# In panda-cms Gemfile, temporarily:
gem "panda-core", path: "../panda/core"

bundle install
bundle exec rspec spec/system/panda/cms/admin/pages/debug_about_blank_spec.rb
```

**IMPORTANT**: Revert Gemfile before committing!

## Files Created

### Panda-Core
- `lib/panda/core/testing/support/system/cuprite_setup.rb` (110 lines)
- `lib/panda/core/testing/support/system/capybara_setup.rb` (62 lines)
- `lib/panda/core/testing/support/system/system_test_helpers.rb` (233 lines)
- `lib/panda/core/testing/support/system/database_connection_helpers.rb` (23 lines)
- Updated: `lib/panda/core/testing/rails_helper.rb` (added system test loading)

### Panda-CMS
- Removed 6 files (~300 lines)
- Updated 3 test files (ES6 → ES5 syntax)

## Root Cause: About:blank Failures

The about:blank navigation failures in panda-cms were caused by:

1. **JavaScript SyntaxError**: Tests used ES6 `const` in `evaluate_script()` calls, which caused browser errors
2. **Silent failures**: `js_errors: false` suppressed the JavaScript errors, causing navigation to about:blank
3. **No visibility**: Tests appeared to "randomly" fail with no clear error message

With the shared infrastructure:
- `js_errors: true` reports JavaScript errors immediately
- ES5 syntax prevents the errors in the first place
- Clear error messages make debugging easier

## Questions?

See the panda-core PR or ask in the team chat!
