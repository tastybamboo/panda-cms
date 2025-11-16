# CI Asset Debugging Guide

## Problem: Ferrum::ProcessTimeoutError in CI

### Symptom
```
Browser did not produce websocket url within 10 seconds, try to increase `:process_timeout`
```

### Root Cause Analysis

This error is **NOT** about Chrome startup timeout. It's a symptom of Rails server failing to boot due to asset resolution issues.

## The Real Issue Chain

1. **Rails boots assets on server start**, not when Chrome first starts
2. Importmaps + Propshaft try to resolve modules during middleware initialization
3. If asset paths are invalid or missing, Rails crashes during boot
4. When Rails/Puma crashes:
   - Puma exits immediately (silently in CI)
   - Capybara waits for the port forever
   - Cuprite waits for Capybara
   - Ferrum kills Chrome after 10 seconds (no handshake possible)
   - Error message: "Browser did not produce websocket url"

## Common Asset Issues in CI

### 1. JavaScript Path Resolution
- **Problem**: ModuleRegistry middleware can't find JavaScript files
- **Cause**: Files copied to wrong location by panda-assets-verify-action
- **Solution**: Copy to both `app/javascript/panda` and `public/panda`

### 2. Importmap Resolution Failures
- **Problem**: Importmap references modules that don't exist in CI
- **Symptoms**: Rails crashes during `importmap.to_json` call
- **Solution**: Ensure all referenced modules are copied to CI environment

### 3. Propshaft Fingerprint Mismatches
- **Problem**: Propshaft serving fingerprints that don't match actual files
- **Cause**: Inconsistent compiled assets vs app code
- **Solution**: Clear asset cache, recompile in CI

### 4. Silent Rails Crashes
- **Problem**: Rails crashes but no error visible
- **Cause**: Puma running in silent mode in CI
- **Solution**: Set `Silent: false, Verbose: true` in CI Puma config

## Debugging Steps

### 1. Enable Verbose Puma Output
```ruby
# In ci_capybara_config.rb
options = {
  Silent: false,  # Always verbose in CI
  Verbose: true,
  PreloadApp: false
}
```

### 2. Wrap App to Catch Middleware Errors
```ruby
wrapped_app = Proc.new do |env|
  begin
    app.call(env)
  rescue => e
    puts "[CI ERROR] Rails middleware error: #{e.message}"
    puts e.backtrace.first(10).join("\n")
    raise e
  end
end
```

### 3. Add Debug Logging to ModuleRegistry
```ruby
# In module_registry.rb
if ENV["RSPEC_DEBUG"]
  puts "[JavaScriptMiddleware] Looking for: #{path}"
  puts "[JavaScriptMiddleware] Checked locations:"
  # List all paths being checked
end
```

### 4. Check Asset Verification Output
Look for the panda-assets-summary artifact in CI:
- Verify all JavaScript files are found
- Check both `app/javascript/panda` and `public/panda` paths
- Ensure HTTP 200 for all assets

## Solutions Applied

### 1. Enhanced Asset Copying (panda-assets-verify-action)
- Copy JavaScript to BOTH locations:
  - `app/javascript/panda` (for ModuleRegistry runtime)
  - `public/panda` (for static verification)
- Added verification logging for all copied files

### 2. ModuleRegistry Fallback Paths (panda-core)
- Primary: Check `app/javascript/panda`
- Fallback: Check `public/panda`
- Rails.root fallback for dummy apps

### 3. Verbose Asset Reporting
- Report ALL assets (not just failures)
- Show HTTP status for each file
- Log file counts and locations

### 4. CI Error Visibility
- Disabled Puma silent mode in CI
- Added middleware error wrapper
- Enhanced debug logging

## Configuration Options to Try

### In config/environments/test.rb:
```ruby
# Option 1: Disable asset compilation
config.assets.compile = false
config.assets.debug = false

# Option 2: Enable fallback for missing assets
config.assets.unknown_asset_fallback = true

# Option 3: Increase timeouts
config.cuprite_process_timeout = 30
```

## Monitoring CI Runs

### Check These Artifacts:
1. **panda-assets-summary.json** - Shows what assets were found/verified
2. **System test logs** - Look for Rails boot errors before Ferrum timeout
3. **Puma output** - Check for middleware initialization errors

### Key Log Messages to Watch For:
- `[CI Config] Starting Puma` - Server attempting to start
- `[CI ERROR] Rails middleware error` - Middleware crash during boot
- `[JavaScriptMiddleware] Looking for` - Asset resolution attempts
- `✅ Copied JS to app/javascript` - Asset copy success

## Future Improvements

1. **Add Rails boot health check** before starting Chrome
2. **Capture and log Rails startup errors** explicitly
3. **Add timeout with helpful message** if server doesn't start
4. **Create asset manifest** for CI to verify all expected files exist
5. **Add pre-boot asset validation** to fail fast with clear errors

## Related Files

- `/Users/james/Projects/panda/panda-assets-verify-action/lib/panda/assets/preparer.rb`
- `/Users/james/Projects/panda/panda-assets-verify-action/lib/panda/assets/verifier.rb`
- `/Users/james/Projects/panda/core/lib/panda/core/module_registry.rb`
- `/Users/james/Projects/panda/core/lib/panda/core/testing/support/system/ci_capybara_config.rb`
- `/Users/james/Projects/panda/cms/.github/workflows/ci.yml`