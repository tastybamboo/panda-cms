# Importmap Isolation Test

If we want to prove that importmap is causing Chrome to crash, we can disable it and see if tests pass.

## Setup

Add to `config/environments/test.rb` or `spec/system_helper.rb`:

```ruby
Rails.application.config.before_initialize do
  if ENV["CI_DISABLE_IMPORTMAP"]
    Rails.application.config.importmap.enabled = false
  end
end
```

## Usage

Run tests with importmap disabled:

```bash
CI_DISABLE_IMPORTMAP=true bundle exec rspec spec/system/
```

Or in CI, set the environment variable:

```yaml
- name: 'Test without importmap'
  env:
    CI_DISABLE_IMPORTMAP: 'true'
    # ... other env vars
  run: |
    bundle exec rspec spec/system/aaa_chrome_boot_spec.rb
```

## Interpretation

- **If Chrome works with importmap disabled**: The importmap configuration is corrupt, has invalid paths, or references missing modules
- **If Chrome still fails**: The issue is elsewhere (shared memory, Chrome binary, fonts, etc.)

This helps isolate whether the problem is:
1. Chrome startup issues (binary, libraries, /dev/shm)
2. Importmap configuration issues (invalid paths, missing modules, corrupted JSON)
3. Page loading issues (server, routes, assets)
