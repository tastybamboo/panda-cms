# Configuration in Panda CMS

Panda CMS uses a structured configuration system based on `dry-configurable`. Configuration is managed through Panda Core, with all settings in a single initializer file.

## Configuration Structure

All Panda configuration is defined in `config/initializers/panda.rb` using the `Panda::Core.configure` block:

```ruby
Panda::Core.configure do |config|
  # Admin interface settings
  config.admin_path = "/admin"
  config.login_page_title = "My Site Admin"
  config.admin_title = "My Site Admin"

  # Authentication providers
  config.authentication_providers = {
    google_oauth2: {
      enabled: true,
      name: "Google",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {
        scope: "email,profile",
        prompt: "select_account",
        hd: "yourdomain.com"
      }
    }
  }

  # Core configuration
  config.session_token_cookie = :panda_session
  config.user_class = "Panda::Core::User"
  config.user_identity_class = "Panda::Core::UserIdentity"
  config.storage_provider = :active_storage
  config.cache_store = :memory_store
end
```

## Available Settings

### Admin Interface Settings

```ruby
config.admin_path            # Admin panel path (default: "/admin")
config.login_page_title      # Login page title (default: "Panda Admin")
config.admin_title           # Admin panel title (default: "Panda Admin")
```

### Authentication Settings

```ruby
config.authentication_providers = {
  google_oauth2: {
    enabled: true,           # Enable this provider
    name: "Google",          # Display name for the button
    client_id: "...",        # OAuth client ID
    client_secret: "...",    # OAuth client secret
    options: {
      scope: "email,profile",
      prompt: "select_account",
      hd: "yourdomain.com"   # Restrict to specific domain (optional)
    }
  },
  microsoft_graph: {         # Additional providers can be configured
    enabled: true,
    name: "Microsoft",
    client_id: "...",
    client_secret: "..."
  }
}
```

### Core Settings

```ruby
config.session_token_cookie   # Session cookie name (default: :panda_session)
config.user_class            # User model class (default: "Panda::Core::User")
config.user_identity_class   # User identity class (default: "Panda::Core::UserIdentity")
config.storage_provider      # Storage backend (default: :active_storage)
config.cache_store          # Cache configuration (default: :memory_store)
```

### Editor Settings (Optional)

For EditorJS customization, use the Panda::Editor configuration:

```ruby
Panda::Editor.configure do |config|
  config.editor_js_tools       # Additional EditorJS tools to load (default: [])
  config.editor_js_tool_config # EditorJS tool configurations (default: {})
  config.custom_renderers      # Custom block renderers (default: {})
end
```

### CMS-Specific Settings (Optional)

For CMS-specific features, you can optionally use a separate configuration block:

```ruby
Panda::CMS.configure do |config|
  config.require_login_to_view = false  # Require authentication to view site
  config.posts.enabled = true           # Enable blog functionality
  config.posts.prefix = "blog"          # URL prefix for blog
end
```

## Configuration Best Practices

### 1. Sensitive Information

Always use Rails credentials for sensitive data like OAuth secrets:

```ruby
# config/credentials.yml.enc
google:
  client_id: "your-google-client-id"
  client_secret: "your-google-client-secret"

microsoft:
  client_id: "your-microsoft-client-id"
  client_secret: "your-microsoft-client-secret"

# config/initializers/panda.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      enabled: true,
      name: "Google",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {
        scope: "email,profile",
        prompt: "select_account",
        hd: "yourdomain.com"
      }
    }
  }
end
```

### 2. Organization

Keep configuration organized by context:

```ruby
# config/initializers/panda.rb
Panda::Core.configure do |config|
  # Admin interface
  config.admin_path = "/admin"
  config.login_page_title = "My Site Admin"
  config.admin_title = "My Site Admin"

  # Authentication
  config.authentication_providers = { ... }

  # Core settings
  config.session_token_cookie = :panda_session
  config.user_class = "Panda::Core::User"
  config.storage_provider = :active_storage
end
```

### 3. Domain Restriction

Restrict admin access to specific email domains:

```ruby
# config/initializers/panda.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      enabled: true,
      name: "Google",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: {
        scope: "email,profile",
        prompt: "select_account",
        hd: "company.com" # Only allow @company.com emails
      }
    }
  }
end
```

### 4. Multiple Authentication Providers

You can enable multiple providers simultaneously:

```ruby
# config/initializers/panda.rb
Panda::Core.configure do |config|
  config.authentication_providers = {
    google_oauth2: {
      enabled: true,
      name: "Google",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      options: { scope: "email,profile", prompt: "select_account" }
    },
    microsoft_graph: {
      enabled: true,
      name: "Microsoft",
      client_id: Rails.application.credentials.dig(:microsoft, :client_id),
      client_secret: Rails.application.credentials.dig(:microsoft, :client_secret)
    }
  }
end
```

## Configuration Loading Order

1. Default values (defined in gem files: `lib/panda-core.rb` and `lib/panda-cms.rb`)
2. Initializer configuration (`config/initializers/panda.rb`)
3. Environment-specific configuration (`config/environments/*.rb`) if needed

## Accessing Configuration

You can access configuration values throughout your application:

```ruby
# In controllers
Panda::Core.config.title

# In views
<%= Panda::Core.config.admin_path %>

# In models
def self.admin_url
  "#{Panda::Core.config.admin_path}/cms"
end

# For CMS-specific config (if using separate CMS configuration)
Panda::CMS.config.posts.prefix
```

## Debugging Configuration

To inspect current configuration:

```ruby
# Rails console
puts Panda::Core.config.to_h
puts Panda::CMS.config.to_h  # If using CMS-specific configuration

# In development.rb
Rails.logger.debug "Panda Core Config: #{Panda::Core.config.to_h}"
```
