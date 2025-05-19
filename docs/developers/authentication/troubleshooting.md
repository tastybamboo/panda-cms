# Authentication Troubleshooting Guide

This guide helps you diagnose and fix common authentication issues in Panda CMS.

## Common Issues

### 1. Missing Provider Gem

**Symptom:**
```
uninitialized constant OmniAuth::Strategies::GoogleOauth2
```

**Solutions:**
1. Add the required gem to your Gemfile:
   ```ruby
   gem 'omniauth-google-oauth2'
   ```
2. Run `bundle install`
3. Restart your Rails server

### 2. Invalid Credentials

**Symptom:**
```
OAuth2::Error: invalid_client
```

**Solutions:**
1. Verify your credentials in `credentials.yml.enc`:
   ```ruby
   rails credentials:edit
   ```
2. Ensure credentials match your OAuth provider settings
3. Check redirect URI matches exactly
4. Verify client ID and secret are correct

### 3. Callback URL Mismatch

**Symptom:**
```
The redirect uri included is not valid
```

**Solutions:**
1. Check your provider's OAuth settings
2. Ensure callback URLs match exactly:
   ```ruby
   # Development
   http://localhost:3000/manage/auth/[provider]/callback

   # Production
   https://your-domain.com/manage/auth/[provider]/callback
   ```
3. Add all required callback URLs to provider settings

### 4. Session Issues

**Symptom:**
- Users get logged out unexpectedly
- Session doesn't persist across requests

**Solutions:**
1. Check session configuration:
   ```ruby
   # config/initializers/session_store.rb
   Rails.application.config.session_store :cookie_store,
     key: '_panda_cms_session',
     expire_after: 8.hours
   ```

2. Verify cookie settings:
   ```ruby
   # config/initializers/panda_cms.rb
   Panda::CMS.configure do |config|
     config.session = {
       same_site: :lax,
       secure: Rails.env.production?
     }
   end
   ```

### 5. Domain Restrictions

**Symptom:**
```
Access denied: Email domain not allowed
```

**Solutions:**
1. Check domain configuration:
   ```ruby
   config.authentication = {
     google: {
       enabled: true,
       hd: "yourdomain.com"  # Remove or modify this line
     }
   }
   ```
2. Verify user's email domain matches allowed domains
3. Add domain to allowed list if needed

## Debugging Tools

### 1. Enable Debug Logging

```ruby
# config/environments/development.rb
config.log_level = :debug

# Add OmniAuth debugging
OmniAuth.config.logger = Rails.logger
```

### 2. Inspect Authentication Flow

Add debugging to your application controller:

```ruby
class ApplicationController < ActionController::Base
  before_action :debug_session

  private

  def debug_session
    return unless Rails.env.development?

    Rails.logger.debug "=== Session Debug ==="
    Rails.logger.debug "User: #{current_user&.inspect}"
    Rails.logger.debug "Session: #{session.to_hash}"
    Rails.logger.debug "===================="
  end
end
```

### 3. Test Authentication in Console

```ruby
# rails console
provider = Panda::CMS.config.authentication[:google]
provider.enabled?  # Check if provider is enabled
provider.client_id # Verify credentials are loaded
```

## Provider-Specific Issues

### Google OAuth

1. **Invalid Client Error**
   - Verify OAuth consent screen is configured
   - Check if project is still in testing mode
   - Verify authorized domains list

2. **Access Denied**
   - Check if user's email domain is allowed
   - Verify OAuth consent screen permissions
   - Check required scopes are configured

### Microsoft OAuth

1. **AADSTS Error Codes**
   - AADSTS50011: Reply URL mismatch
   - AADSTS700016: Application not found
   - AADSTS7000218: Request body must contain client_assertion

2. **Domain Verification**
   - Verify tenant ID configuration
   - Check multi-tenant settings
   - Verify domain in Azure AD

### GitHub OAuth

1. **Application Suspended**
   - Check rate limits
   - Verify application is approved
   - Review GitHub OAuth app settings

2. **Scope Issues**
   - Verify required scopes are configured
   - Check organization access settings
   - Review user authorization status

## Security Best Practices

### 1. Credential Protection

- Use Rails credentials or environment variables
- Never commit secrets to version control
- Rotate secrets periodically

### 2. SSL/TLS

- Always use HTTPS in production
- Configure secure cookie settings
- Set appropriate SSL options

### 3. Session Security

- Configure session timeout
- Implement CSRF protection
- Use secure session storage

## Getting Help

1. Check Rails logs for detailed error messages
2. Review provider documentation
3. Search GitHub issues
4. Contact provider support

## Maintenance

### Regular Checks

1. Monitor authentication success rates
2. Review failed login attempts
3. Check for provider status updates
4. Update gems regularly

### Security Audits

1. Review authorized applications
2. Check access logs
3. Verify SSL certificates
4. Update security settings
