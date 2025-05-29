# Configuration in Panda CMS

Panda CMS uses a structured configuration system based on `dry-configurable`. This guide explains how configuration works and how to use it effectively.

## Configuration Structure

The configuration is organized into logical groups:

```ruby
Panda::CMS.configure do |config|
  # Site configuration
  config.title = "My Site"
  config.admin_path = "/manage"
  config.require_login_to_view = false
  config.url = "https://example.com"

  # Session configuration
  config.session.key = "_my_custom_session"
  config.session.expire_after = 12.hours
  config.session.same_site = :lax
  config.session.secure = true

  # Posts/blog configuration
  config.posts.enabled = true
  config.posts.prefix = "news"
  config.posts.layouts.index = "news_index"
  config.posts.layouts.show = "news_article"
end
```

## Available Settings

### Site Settings

```ruby
config.title                 # Site title (default: "Demo Site")
config.admin_path           # Admin panel path (default: "/admin")
config.require_login_to_view # Require authentication to view site (default: false)
config.url                  # Site URL, used for callbacks and links
```

### Session Settings

```ruby
config.session.key          # Session cookie name (default: "_panda_cms_session")
config.session.same_site    # SameSite cookie setting (default: :lax)
config.session.secure       # Require HTTPS (default: true in production)
config.session.expire_after # Session duration (default: 8.hours)
config.session.domain       # Cookie domain (optional)
config.session.path        # Cookie path (optional)
```

### Posts/Blog Settings

```ruby
config.posts.enabled        # Enable blog functionality (default: true)
config.posts.prefix         # URL prefix for blog (default: "blog")
config.posts.layouts.index  # Layout for post index (default: "posts")
config.posts.layouts.show   # Layout for single post (default: "post")
config.posts.layouts.by_month # Layout for monthly archives (default: "posts")
```

### Editor Settings

```ruby
config.editor_js_tools      # Additional EditorJS tools to load (default: [])
config.editor_js_tool_config # EditorJS tool configurations (default: {})
```

## Configuration Best Practices

### 1. Environment-Specific Configuration

Use environment-specific configuration files:

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

### 2. Sensitive Information

Use Rails credentials for sensitive data:

```ruby
# config/credentials.yml.enc
panda_cms:
  session:
    secret: "your-secret-key"
  authentication:
    google:
      client_id: "google-client-id"
      client_secret: "google-client-secret"

# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.authentication.google = {
    enabled: true,
    client_id: Rails.application.credentials.dig(:panda_cms, :authentication, :google, :client_id),
    client_secret: Rails.application.credentials.dig(:panda_cms, :authentication, :google, :client_secret)
  }
end
```

### 3. Organization

Keep configuration organized by context:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  # Site identity
  config.title = "My Site"
  config.url = "https://example.com"

  # Security
  config.require_login_to_view = true
  config.session.secure = true

  # Content
  config.posts.enabled = true
  config.posts.prefix = "news"
end
```

### 4. Documentation

Document custom configuration:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  # Custom session name for multi-site setup
  # This allows running multiple Panda CMS instances on subdomains
  config.session.key = "_site1_session"
  config.session.domain = ".example.com"

  # Restrict access to specific email domains
  config.authentication.google = {
    enabled: true,
    hd: "company.com" # Only allow @company.com emails
  }
end
```

## Configuration Loading Order

1. Default values (defined in `lib/panda-cms.rb`)
2. Environment-specific configuration (`config/environments/*.rb`)
3. Initializer configuration (`config/initializers/panda_cms.rb`)

## Accessing Configuration

You can access configuration values throughout your application:

```ruby
# In controllers
Panda::CMS.config.title

# In views
<%= Panda::CMS.config.posts.prefix %>

# In models
def self.blog_path
  "/#{Panda::CMS.config.posts.prefix}"
end
```

## Extending Configuration

To add custom configuration groups:

```ruby
# lib/my_extension.rb
module Panda
  module CMS
    setting :my_extension do
      setting :feature_enabled, default: false
      setting :custom_option, default: "default"
    end
  end
end

# Usage
Panda::CMS.configure do |config|
  config.my_extension.feature_enabled = true
  config.my_extension.custom_option = "custom"
end
```

## Debugging Configuration

To inspect current configuration:

```ruby
# Rails console
puts Panda::CMS.config.to_h

# In development.rb
Rails.logger.debug "Panda CMS Config: #{Panda::CMS.config.to_h}"
```
