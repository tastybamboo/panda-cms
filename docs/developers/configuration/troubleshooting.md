# Configuration Troubleshooting

This guide helps you diagnose and fix common configuration issues in Panda CMS.

## Common Issues

### 1. Configuration Not Applied

**Symptom:** Configuration changes don't take effect.

**Possible Causes:**
1. Configuration loaded in wrong order
2. Rails cache issues
3. Initializer timing

**Solutions:**

```ruby
# 1. Check loading order - move to correct initializer
# config/initializers/01_panda_cms.rb  # Use number prefix for ordering
Panda::CMS.configure do |config|
  # Your configuration here
end

# 2. Clear Rails cache
Rails.cache.clear

# 3. Use proper initializer timing
config.before_initialize do
  Panda::CMS.configure do |config|
    # Time-sensitive configuration here
  end
end
```

### 2. Session Issues

**Symptom:** Session problems (not persisting, conflicts)

**Solutions:**

```ruby
# 1. Check domain configuration
config.session.domain = ".example.com"  # Include dot for subdomains

# 2. Verify path settings
config.session.path = "/app"  # Must match your mount point

# 3. Debug session configuration
Rails.logger.debug "Session Config: #{Panda::CMS.config.session.to_h}"
```

### 3. Environment-Specific Issues

**Symptom:** Configuration works in development but not in production

**Solutions:**

```ruby
# 1. Use environment detection
Panda::CMS.configure do |config|
  if Rails.env.production?
    config.session.secure = true
    config.session.same_site = :strict
  else
    config.session.secure = false
    config.session.same_site = :lax
  end
end

# 2. Check credentials loading
if Rails.application.credentials.dig(:panda_cms).nil?
  Rails.logger.error "Missing Panda CMS credentials!"
end
```

## Debugging Techniques

### 1. Configuration Inspection

```ruby
# In Rails console
pp Panda::CMS.config.to_h  # Pretty print full configuration

# In initializer
Rails.logger.debug "=== Panda CMS Configuration ==="
Rails.logger.debug JSON.pretty_generate(Panda::CMS.config.to_h)
```

### 2. Load Order Debugging

```ruby
# config/initializers/panda_cms.rb
Rails.logger.debug "Loading Panda CMS configuration..."

Panda::CMS.configure do |config|
  Rails.logger.debug "Before config: #{config.session.key}"
  config.session.key = "_custom_session"
  Rails.logger.debug "After config: #{config.session.key}"
end

Rails.logger.debug "Panda CMS configuration loaded"
```

### 3. Middleware Inspection

```ruby
# config/initializers/debug_middleware.rb
Rails.application.config.middleware.tap do |middleware|
  Rails.logger.debug "=== Middleware Stack ==="
  middleware.each do |m|
    Rails.logger.debug "  #{m.inspect}"
  end
end
```

## Common Gotchas

### 1. Nested Configuration

```ruby
# Wrong - Hash will be overwritten
config.authentication = {
  google: {enabled: true}
}

# Correct - Use nested configuration
config.authentication.google.enabled = true
```

### 2. Dynamic Values

```ruby
# Wrong - Evaluated once at load time
config.session.secure = Rails.env.production?

# Correct - Use lambda for dynamic values
config.session.secure = -> { Rails.env.production? }
```

### 3. Credential Access

```ruby
# Wrong - Credentials not available during boot
config.secret = Rails.application.credentials.secret

# Correct - Use lambda or configure after boot
config.secret = -> { Rails.application.credentials.secret }
```

## Configuration Validation

Add validation to catch issues early:

```ruby
# config/initializers/validate_panda_cms_config.rb
Rails.application.config.after_initialize do
  config = Panda::CMS.config

  errors = []

  # Validate required settings
  errors << "Missing site URL" if config.url.nil?

  # Validate session settings
  if config.session.secure && !config.url.to_s.start_with?("https://")
    errors << "Secure sessions require HTTPS URL"
  end

  # Validate authentication settings
  if config.authentication.google&.enabled
    unless config.authentication.google.client_id
      errors << "Google authentication enabled but missing client_id"
    end
  end

  # Raise error if any validation failed
  if errors.any?
    raise <<~ERROR
      Invalid Panda CMS configuration:
      #{errors.map { |e| "  - #{e}" }.join("\n")}
    ERROR
  end
end
```

## Best Practices for Troubleshooting

1. **Isolate Issues**
   - Test one configuration change at a time
   - Use environment-specific configuration files
   - Add detailed logging around problematic areas

2. **Version Control**
   - Keep configuration changes in separate commits
   - Document configuration changes in commit messages
   - Use git bisect to find problematic changes

3. **Documentation**
   - Comment non-obvious configuration choices
   - Keep a changelog of configuration changes
   - Document environment-specific requirements

4. **Testing**
   - Add tests for critical configuration
   - Verify configuration in different environments
   - Test configuration changes before deployment
```
