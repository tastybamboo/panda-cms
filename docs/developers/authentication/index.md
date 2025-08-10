# Authentication in Panda CMS

> **Note**: Authentication is now handled by Panda Core. This documentation is for reference only.

## Authentication System

As of Panda CMS v0.8.0, authentication has been moved to [Panda Core](https://github.com/tastybamboo/panda-core). 

For authentication documentation, please see:
- [Panda Core Authentication Guide](https://github.com/tastybamboo/panda-core/tree/main/docs/authentication)
- [Migration Guide](https://github.com/tastybamboo/panda-core/blob/main/docs/authentication/migration.md)

## What's Changed

1. **User Model**: Now uses `Panda::Core::User` instead of `Panda::CMS::User`
2. **Configuration**: Authentication is configured in `Panda::Core`, not `Panda::CMS`
3. **Database**: Users are stored in `panda_core_users` table

## Quick Reference

### Configuring Authentication

Authentication providers are now configured in your panda_core initializer:

```ruby
# config/initializers/panda_core.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret)
    }
  }
end
```

### Accessing Current User

In controllers and views:
```ruby
# Still works the same way
Current.user
```

### Admin Access

Admin routes and permissions continue to work as before, but now use `Panda::Core::User#is_admin` instead of `admin`.

## Legacy Documentation

For applications still using older versions of Panda CMS with built-in authentication, see the [legacy authentication documentation](providers.md).