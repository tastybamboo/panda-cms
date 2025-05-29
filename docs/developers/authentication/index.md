# Authentication in Panda CMS

Panda CMS provides a flexible authentication system built on OmniAuth. This section covers everything you need to know about authentication in your Panda CMS application.

## Topics

1. [Authentication Providers](providers.md)
   - Available providers
   - Configuration and setup
   - Troubleshooting
   - Security considerations

## Quick Start

1. Choose your authentication provider(s) (Google, Microsoft, GitHub)
2. Add the required gems to your Gemfile
3. Configure your credentials
4. Enable the providers in your Panda CMS configuration

Example minimal setup for Google authentication:

```ruby
# Gemfile
gem 'omniauth-google-oauth2', '~> 1.1'

# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.authentication = {
    google: {
      enabled: true,
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret)
    }
  }
end
```

## Common Use Cases

1. **Single Provider Setup**
   - Best for simple applications
   - Recommended for getting started
   - See [Authentication Providers](providers.md) for setup instructions

2. **Multiple Providers**
   - Allow users to choose their preferred login method
   - Each provider can be configured independently
   - See provider-specific documentation for details

3. **Domain-Restricted Access**
   - Limit access to specific email domains
   - Commonly used with Google authentication
   - See Google provider configuration for details

## Best Practices

1. **Security**
   - Always use HTTPS in production
   - Keep credentials secure
   - Use environment-specific configurations

2. **User Experience**
   - Enable appropriate providers for your audience
   - Consider auto-provisioning settings
   - Provide clear login instructions

3. **Maintenance**
   - Keep provider gems updated
   - Monitor authentication logs
   - Test authentication flows regularly

## Need Help?

- Check the [Troubleshooting](providers.md#troubleshooting) section
- Review provider-specific documentation
- Submit issues on GitHub
