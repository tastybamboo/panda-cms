# Configuration Organization

This guide explains how configuration is organized in Panda CMS and best practices for managing it.

## Configuration Structure

### Core Configuration

The core configuration is defined in `lib/panda-cms.rb`. This is where all configuration groups and their default values are defined:

```ruby
module Panda
  module CMS
    extend Dry::Configurable

    # Site settings
    setting :title, default: "Demo Site"
    setting :admin_path, default: "/admin"
    setting :require_login_to_view, default: false
    setting :url

    # Session settings
    setting :session do
      setting :key, default: "_panda_cms_session"
      setting :expire_after, default: 8.hours
      setting :same_site, default: :lax
      setting :secure, default: -> { Rails.env.production? }
      setting :domain
      setting :path
    end

    # Authentication settings
    setting :authentication do
      setting :providers, default: []
      setting :after_login, default: nil
      setting :after_logout, default: nil
      setting :auto_provision, default: false
    end

    # Posts/blog settings
    setting :posts do
      setting :enabled, default: true
      setting :prefix, default: "blog"
      setting :layouts do
        setting :index, default: "posts"
        setting :show, default: "post"
        setting :by_month, default: "posts"
      end
    end
  end
end
```

### Engine Configuration

The engine configuration in `lib/panda/cms/engine.rb` handles Rails-specific setup:

```ruby
module Panda
  module CMS
    class Engine < ::Rails::Engine
      isolate_namespace Panda::CMS

      initializer "panda_cms.session" do |app|
        session_config = Panda::CMS.config.session
        app.config.session_store :cookie_store, {
          key: session_config.key,
          expire_after: session_config.expire_after,
          same_site: session_config.same_site,
          secure: session_config.secure,
          domain: session_config.domain,
          path: session_config.path
        }.compact
      end
    end
  end
end
```

## Configuration Files

### 1. Application Configuration

Place your application's Panda CMS configuration in an initializer:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  # Site identity
  config.title = "My Application"
  config.url = "https://example.com"

  # Security settings
  config.require_login_to_view = true
  config.session.secure = true

  # Content settings
  config.posts.prefix = "news"
  config.posts.layouts.show = "article"
end
```

### 2. Environment-Specific Configuration

Use environment files for environment-specific settings:

```ruby
# config/environments/production.rb
Panda::CMS.configure do |config|
  config.session.secure = true
  config.session.same_site = :strict
end

# config/environments/development.rb
Panda::CMS.configure do |config|
  config.session.secure = false
  config.session.same_site = :lax
end
```

### 3. Sensitive Configuration

Use Rails credentials for sensitive data:

```yaml
# config/credentials.yml.enc
panda_cms:
  authentication:
    google:
      client_id: "google-client-id"
      client_secret: "google-client-secret"
    github:
      client_id: "github-client-id"
      client_secret: "github-client-secret"
```

Access in your configuration:

```ruby
Panda::CMS.configure do |config|
  config.authentication.providers = [
    {
      name: "google",
      strategy: :google_oauth2,
      client_id: Rails.application.credentials.dig(:panda_cms, :authentication, :google, :client_id),
      client_secret: Rails.application.credentials.dig(:panda_cms, :authentication, :google, :client_secret)
    }
  ]
end
```

## Best Practices

### 1. Group Related Settings

Organize settings into logical groups:

```ruby
Panda::CMS.configure do |config|
  # Authentication group
  config.authentication.providers = [...]
  config.authentication.auto_provision = true
  config.authentication.after_login = -> { ... }

  # Content group
  config.posts.enabled = true
  config.posts.prefix = "news"
  config.posts.layouts.index = "news_index"
end
```

### 2. Use Descriptive Names

Choose clear, descriptive names for configuration settings:

```ruby
# Bad
config.auth_ap = true  # Unclear what "ap" means

# Good
config.authentication.auto_provision = true  # Clear and descriptive
```

### 3. Document Configuration

Add comments explaining non-obvious settings:

```ruby
Panda::CMS.configure do |config|
  # Use custom session name for multi-site setup
  # This allows different sessions for each subdomain
  config.session.key = "_site1_session"
  config.session.domain = ".example.com"

  # Restrict access to specific email domains
  # Only allows @company.com email addresses to log in
  config.authentication.google = {
    enabled: true,
    hd: "company.com"
  }
end
```

### 4. Validate Configuration

Add validation for critical settings:

```ruby
Rails.application.config.after_initialize do
  config = Panda::CMS.config

  if config.session.secure && !config.url.to_s.start_with?("https://")
    raise "Secure sessions require HTTPS URL"
  end

  if config.authentication.providers.empty? && config.require_login_to_view
    raise "Authentication providers required when login is required"
  end
end
```

### 5. Use Environment Variables

Use environment variables for values that change between environments:

```ruby
Panda::CMS.configure do |config|
  config.url = ENV.fetch("SITE_URL", "http://localhost:3000")

  if provider = ENV["AUTH_PROVIDER"]
    config.authentication.providers = [{
      name: provider,
      enabled: true,
      client_id: ENV.fetch("#{provider.upcase}_CLIENT_ID"),
      client_secret: ENV.fetch("#{provider.upcase}_CLIENT_SECRET")
    }]
  end
end
```

### 6. Keep It DRY

Extract common configuration into shared methods:

```ruby
# config/initializers/panda_cms.rb
def configure_provider(name, options = {})
  {
    name: name,
    enabled: true,
    client_id: Rails.application.credentials.dig(:panda_cms, :authentication, name, :client_id),
    client_secret: Rails.application.credentials.dig(:panda_cms, :authentication, name, :client_secret)
  }.merge(options)
end

Panda::CMS.configure do |config|
  config.authentication.providers = [
    configure_provider(:google, hd: "company.com"),
    configure_provider(:github, scope: "user:email")
  ]
end
```

## Configuration Loading Order

Understanding the configuration loading order is crucial:

1. Default values (defined in `lib/panda-cms.rb`)
2. Gem-level configuration (in `lib/panda/cms/engine.rb`)
3. Environment-specific configuration (`config/environments/*.rb`)
4. Application configuration (`config/initializers/panda_cms.rb`)
5. Runtime configuration (if any, during application execution)

This order allows for proper overriding of settings while maintaining sensible defaults.
