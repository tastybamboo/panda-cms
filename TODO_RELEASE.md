# panda-cms Release TODO

## Current Status
- **panda-editor v0.3.0**: ✅ Released
- **panda-core v0.4.0**: ✅ Released
- **panda-cms v0.8.3**: ⚠️ Test failures need fixing (43/182 failing)
- **panda-cms-pro v0.1.0**: ✅ Tests passing (waiting on panda-cms)

## Changes Already Made
- ✅ Fixed Phlex component prop accessors (use `@editable`, `@key` instead of method calls)
- ✅ Committed to branch: `feat/unified-config-v0.8.3`
- ✅ Updated panda-cms to use new panda-core v0.4.0

## Remaining Issues to Fix

### 1. Test Fixture/Database Issues

**Problem**: Components can't find blocks during tests, even though fixtures exist and load correctly.

**Error Example**:
```
Panda::CMS::MissingBlockError: Block with key plain_text not found for page About
```

**Investigation Steps**:
1. Check if `Current.page.panda_cms_template_id` is properly set in tests
2. Verify Block associations are working in test environment
3. Debug why `Block.find_by(key: @key, panda_cms_template_id: ...)` returns nil
4. Check if fixtures are using correct association names (`template:` vs `panda_cms_template:`)
5. Verify the Page model properly loads its template association

**Files to Check**:
- `spec/fixtures/panda_cms_blocks.yml` - Block fixtures
- `spec/fixtures/panda_cms_pages.yml` - Page fixtures
- `spec/fixtures/panda_cms_templates.yml` - Template fixtures
- `app/models/panda/cms/block.rb` - Block model associations
- `app/models/panda/cms/page.rb` - Page model associations
- `app/controllers/panda/cms/pages_controller.rb` - How Current.page is set

**Possible Solutions**:
- Ensure `Current.page` includes the template association in tests
- Add `includes(:template)` when loading pages in tests
- Check if fixtures need explicit foreign key IDs instead of association names
- Verify database schema has correct foreign key columns

### 2. OAuth Mock Setup Issues

**Problem**: Admin tests failing because login redirects to `/admin/login` instead of admin dashboard.

**Error Example**:
```
expected ["/admin", "/admin/cms"] to include "/admin/login"
```

**Investigation Steps**:
1. Check OmniAuth test helper in `spec/system/support/omni_auth_helpers.rb`
2. Verify mock OAuth provider is properly configured
3. Check if user fixtures are needed (currently missing)
4. Verify `Panda::Core::User` model is being used correctly

**Files to Check**:
- `spec/system/support/omni_auth_helpers.rb` - OAuth mock helpers
- `spec/rails_helper.rb` - Test configuration
- `config/initializers/omniauth.rb` (in dummy app)

**Possible Solutions**:
- Update OAuth mock to work with `Panda::Core::User` instead of `Panda::CMS::User`
- Add user fixtures or factory methods for test users
- Fix authentication flow in test helpers

### 3. Component Rendering Issues

**Problem**: Some components may still have issues accessing Phlex props.

**Investigation Steps**:
1. Check if all components use `@prop_name` instead of `prop_name` method calls
2. Verify `Panda::Core::Base` properly initializes Literal properties
3. Test components in isolation with proper prop values

**Files to Check**:
- `app/components/panda/cms/text_component.rb` - Already fixed
- `app/components/panda/cms/rich_text_component.rb` - Already fixed
- `app/components/panda/cms/code_component.rb` - Already fixed
- Any other custom components

## Release Steps (After Fixes)

### 1. Merge and Prepare
```bash
cd /Users/james/Projects/panda/cms
git checkout main
git merge feat/unified-config-v0.8.3
```

### 2. Update Dependencies
```bash
# Update to use released panda-core v0.4.0
bundle update panda-core

# Update panda-editor if needed
bundle update panda-editor
```

### 3. Verify Tests Pass
```bash
bundle exec rspec
# Should show: 182 examples, 0 failures
```

### 4. Create CHANGELOG
Create `CHANGELOG.md` with:
- Phlex component architecture updates
- Bug fixes
- Dependency updates (panda-core v0.4.0, panda-editor v0.3.0)

### 5. Version Bump
Determine appropriate version (0.9.0 for minor changes, 0.8.4 for patch):
```bash
# Edit lib/panda-cms/version.rb
# Update VERSION constant

bundle update panda-cms
```

### 6. Commit and Tag
```bash
git add -A
git commit -m "Release panda-cms v0.X.X

- Update to panda-core v0.4.0
- Fix Phlex component prop accessors
- [other changes]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git tag -a v0.X.X -m "Release v0.X.X: [brief description]"
git push origin main
git push origin v0.X.X
```

### 7. Release panda-cms-pro
Once panda-cms is released:
```bash
cd /Users/james/Projects/panda/cms-pro

# Update dependency
# Edit Gemfile.lock or gemspec to reference panda-cms v0.X.X
bundle update panda-cms

# Create CHANGELOG.md
# Bump version in lib/panda/cms/pro/version.rb
bundle update panda-cms-pro

# Commit and tag
git add -A
git commit -m "Release panda-cms-pro v0.X.X"
git tag -a v0.X.X -m "Release v0.X.X"
git push origin main
git push origin v0.X.X
```

## Testing Strategy

### Quick Tests to Verify Fixes
```bash
# Test homepage (should pass)
bundle exec rspec spec/system/website_spec.rb:8

# Test about page (currently fails)
bundle exec rspec spec/system/website_spec.rb:20

# Test admin login (currently fails)
bundle exec rspec spec/system/panda/cms/admin/pages/add_page_spec.rb:37
```

### Full Test Suite
```bash
bundle exec rspec --format documentation
```

## Key Files Modified

### Already Fixed
- `app/components/panda/cms/text_component.rb`
- `app/components/panda/cms/rich_text_component.rb`
- `app/components/panda/cms/code_component.rb`

### Need Investigation
- `spec/fixtures/*.yml` - Fixture files
- `spec/rails_helper.rb` - Test configuration
- `spec/system/support/omni_auth_helpers.rb` - OAuth mocks
- Models: Block, Page, Template associations

## Notes

- Current branch with fixes: `feat/unified-config-v0.8.3`
- panda-core dependency: should use v0.4.0 (released)
- panda-editor dependency: should use v0.3.0 (released)
- Git remotes are configured to use SSH
- Test database: `panda_cms_dummy_test`

## Quick Commands Reference

```bash
# Reset test database
cd /Users/james/Projects/panda/cms
bundle exec rails db:reset RAILS_ENV=test

# Run specific test
bundle exec rspec spec/path/to/spec.rb:LINE_NUMBER

# Run all tests
bundle exec rspec

# Check test count
bundle exec rspec --format progress 2>&1 | grep "examples.*failures"

# Update bundle after version changes
bundle update [gem-name]
```
