# JavaScript Test Troubleshooting Guide

Quick reference for diagnosing and fixing JavaScript-related test failures in Panda CMS.

## Common Symptoms

### 1. "Could not find node with given id" Errors
**Cause**: JavaScript not loading, form elements not rendered properly  
**Debug**: Check for Panda CMS script tags in HTML output

### 2. `pandaCmsLoaded: nil` in Test Debug Output
**Cause**: JavaScript bundle not being included in page  
**Solution**: Verify asset compilation and helper inclusion

### 3. Disabled Form Buttons
**Symptom**: `<button ... disabled="">Create Page</button>`  
**Cause**: JavaScript not executing to enable buttons  
**Check**: Look for script tags and JavaScript errors

### 4. Tests Timing Out (20+ seconds)
**Cause**: `wait_for_panda_cms_assets` waiting for assets that never load  
**Solution**: Fix asset loading or remove problematic wait calls

## Quick Diagnostics

### Check Asset Compilation
```bash
# Compile assets
bundle exec rake app:panda_cms:assets:compile

# Verify assets exist
ls -la spec/dummy/public/panda-cms-assets/

# Check bundle content
head -20 spec/dummy/public/panda-cms-assets/panda-cms-*.js
grep "pandaCmsLoaded" spec/dummy/public/panda-cms-assets/panda-cms-*.js
```

### Check Test Environment Asset Loading
```bash
# Run with debug output
RAILS_ENV=test bundle exec rails runner "
puts 'AssetLoader.use_github_assets?: ' + Panda::CMS::AssetLoader.use_github_assets?.to_s
puts 'JavaScript URL: ' + Panda::CMS::AssetLoader.javascript_url
puts 'Compiled assets available?: ' + Panda::CMS::AssetLoader.send(:compiled_assets_available?).to_s
"
```

### Verify HTML Output in Tests
Look for these in test failure output:
- ✅ `<script src="/panda-cms-assets/panda-cms-0.7.4.js" defer>` 
- ❌ No Panda CMS script tags (only FontAwesome, jQuery)
- ❌ `<button ... disabled="">` (should not be disabled)

## Common Fixes

### 1. Asset Compilation Issues
```bash
# Clean and recompile
rm -rf spec/dummy/public/panda-cms-assets/
rm -rf spec/dummy/tmp/panda_cms_assets/
bundle exec rake app:panda_cms:assets:compile
```

### 2. Missing Helper Integration
Ensure `AssetHelper` is included in engine:
```ruby
# lib/panda/cms/engine.rb
config.to_prepare do
  ApplicationController.helper(::ApplicationHelper)
  ApplicationController.helper(Panda::CMS::AssetHelper)
end
```

### 3. Version Mismatch Issues
Check `asset_version` method in `AssetLoader`:
```ruby
def asset_version
  if Rails.env.test?
    Panda::CMS::VERSION  # Use VERSION constant in test
  else
    `git rev-parse --short HEAD`.strip
  end
end
```

### 4. Flaky Test Handling
Mark intermittent tests as flaky:
```ruby
it "shows validation errors", :flaky do
  # Test that sometimes fails due to timing
end
```

## Environment-Specific Checks

### Development
- Uses importmap assets by default
- JavaScript loaded from `app/javascript/panda/cms/`
- No compilation required

### Test  
- Uses compiled bundles from `spec/dummy/public/panda-cms-assets/`
- Requires `bundle exec rake app:panda_cms:assets:compile`
- AssetLoader should return local URLs, not GitHub URLs

### Production
- Downloads compiled bundles from GitHub releases
- Uses integrity checks and CDN distribution
- Environment variable: `PANDA_CMS_USE_GITHUB_ASSETS=true`

## Test Retry Configuration

For handling flaky tests, ensure retry mechanism is configured:

```ruby
# spec/rails_helper.rb
config.around(:each, :flaky) do |example|
  retry_count = example.metadata[:retry] || 3
  retry_count.times do |i|
    example.run
    break unless example.exception
    
    if i < retry_count - 1
      puts "\n[RETRY] Test failed, retrying... (attempt #{i + 2}/#{retry_count})"
      example.instance_variable_set(:@exception, nil)
      sleep 1
    end
  end
end
```

## Emergency Reset

If everything is broken, try this sequence:

```bash
# 1. Clean everything
rm -rf spec/dummy/public/panda-cms-assets/
rm -rf spec/dummy/tmp/panda_cms_assets/
rm -rf spec/dummy/tmp/cache/

# 2. Recompile assets
cd spec/dummy
bundle exec rake app:panda_cms:assets:compile
cd ../..

# 3. Verify compilation
ls -la spec/dummy/public/panda-cms-assets/
head -10 spec/dummy/public/panda-cms-assets/panda-cms-*.js

# 4. Run a single test to verify
bundle exec rspec spec/system/panda/cms/admin/pages/add_page_spec.rb:45 -v
```

## Key Files to Check

| File | Purpose | Common Issues |
|------|---------|---------------|
| `lib/panda/cms/asset_loader.rb` | Asset loading logic | Version mismatch, URL resolution |
| `lib/panda/cms/engine.rb` | Engine configuration | Missing helper inclusion |
| `app/helpers/panda/cms/asset_helper.rb` | Asset helper methods | Not available in views |
| `lib/tasks/assets.rake` | Asset compilation | Bundle generation issues |
| `spec/dummy/public/panda-cms-assets/` | Compiled assets | Missing or outdated files |

## Contact

For additional help, refer to:
- Main documentation: `docs/JAVASCRIPT_TEST_FIXES.md`
- Engine configuration: `lib/panda/cms/engine.rb`
- Asset compilation: `lib/tasks/assets.rake`