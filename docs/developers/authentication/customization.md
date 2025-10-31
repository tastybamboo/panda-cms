# Customizing Authentication

This guide covers how to customize the authentication system in your Panda CMS application.

## Custom User Data

### Mapping Provider Data

You can customize how provider data maps to your user model:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.authentication.user_mapping = lambda do |auth|
    {
      email: auth.info.email,
      name: auth.info.name,
      avatar_url: auth.info.image,
      provider: auth.provider,
      uid: auth.uid,
      # Add custom fields here
      company: auth.extra.raw_info.company,
      location: auth.extra.raw_info.location
    }
  end
end
```

### Custom User Creation

Override the default user creation process:

```ruby
Panda::CMS.configure do |config|
  config.authentication.create_user = lambda do |auth_data|
    User.create!(
      email: auth_data.info.email,
      name: auth_data.info.name,
      role: determine_user_role(auth_data.info.email)
    )
  end

  def determine_user_role(email)
    if email.end_with?("@admin-domain.com")
      "admin"
    else
      "user"
    end
  end
end
```

## Custom Authorization Rules

### Domain Restrictions

Restrict access to specific email domains:

```ruby
Panda::CMS.configure do |config|
  config.authentication.authorize = lambda do |auth_data|
    allowed_domains = ["company.com", "partner.org"]
    email_domain = auth_data.info.email.split("@").last
    allowed_domains.include?(email_domain)
  end
end
```

### Role-Based Access

Implement custom role assignment:

```ruby
Panda::CMS.configure do |config|
  config.authentication.assign_role = lambda do |user, auth_data|
    case auth_data.info.email
    when /(@admin\.com$)/
      user.update(role: "admin")
    when /(@editor\.com$)/
      user.update(role: "editor")
    else
      user.update(role: "viewer")
    end
  end
end
```

## Custom UI

### Login Page

Override the default login page template:

```erb
# app/views/panda/core/admin/sessions/new.html.erb
<div class="login-container">
  <h2><%= Panda::Core.config.login_page_title || "Sign in to your account" %></h2>

  <% Panda::Core.config.authentication_providers.each do |provider, provider_config| %>
    <% provider_name = provider_config&.dig(:name) || provider.to_s.humanize %>
    <% provider_path = provider_config&.dig(:path_name) || provider %>

    <%= form_tag "#{Panda::Core.config.admin_path}/auth/#{provider_path}", method: "post", data: {turbo: false} do %>
      <button type="submit" class="login-button <%= provider %>">
        <i class="fa-brands fa-<%= oauth_provider_icon(provider) %>"></i>
        Sign in with <%= provider_name %>
      </button>
    <% end %>
  <% end %>

  <!-- Add custom login options here -->
  <%= render "custom_login_options" if lookup_context.exists?("custom_login_options") %>
</div>
```

**Important:** OAuth login forms must use POST method for CSRF protection (CVE-2015-9284). Do not use `link_to` for OAuth authentication endpoints.

### Error Messages

Customize authentication error messages:

```ruby
# config/locales/en.yml
en:
  panda:
    cms:
      admin:
        sessions:
          unauthorized: "Access denied. Please contact your administrator."
          domain_restricted: "Login is restricted to approved email domains."
          create:
            success: "Welcome back, %{name}!"
```

## Custom Callbacks

### After Login

Execute custom code after successful login:

```ruby
Panda::CMS.configure do |config|
  config.authentication.after_login = lambda do |user, auth_data|
    # Update last login timestamp
    user.update(last_login_at: Time.current)

    # Sync user data with external service
    ExternalService.sync_user(user)

    # Send welcome email for new users
    UserMailer.welcome_email(user).deliver_later if user.sign_in_count == 1
  end
end
```

### After Logout

Execute custom code after logout:

```ruby
Panda::CMS.configure do |config|
  config.authentication.after_logout = lambda do |user|
    # Clear user-specific cache
    Rails.cache.delete("user_#{user.id}_permissions")

    # Log the logout event
    ActivityLog.create(
      user_id: user.id,
      action: "logout",
      ip_address: request.remote_ip
    )
  end
end
```

## Advanced Customization

### Custom Provider Integration

Add support for additional OAuth providers:

```ruby
# config/initializers/panda_cms.rb
Panda::CMS.configure do |config|
  config.authentication.custom_provider = {
    name: "custom_oauth2",
    strategy: :custom_oauth2,
    gem_name: "omniauth-custom-provider",
    defaults: {
      client_id: ENV["CUSTOM_OAUTH_ID"],
      client_secret: ENV["CUSTOM_OAUTH_SECRET"],
      scope: "read,write",
      authorize_params: {
        access_type: "offline",
        prompt: "consent"
      }
    }
  }
end
```

### Session Management

Customize session handling using the session configuration group:

```ruby
Panda::CMS.configure do |config|
  # Session configuration
  config.session.key = "_my_custom_session"
  config.session.expire_after = 8.hours
  config.session.same_site = :lax
  config.session.secure = true # Force HTTPS
  config.session.domain = "example.com" # Optional: Set cookie domain
  config.session.path = "/app" # Optional: Set cookie path
end
```

The session configuration supports all standard Rails cookie store options:
- `key`: The name of the session cookie
- `expire_after`: Session timeout duration
- `same_site`: SameSite cookie attribute (:lax, :strict, or :none)
- `secure`: Whether the cookie requires HTTPS
- `domain`: Cookie domain scope
- `path`: Cookie path scope

For multi-site setups, you can use different session names:

```ruby
# Site 1
Panda::CMS.configure do |config|
  config.session.key = "_site1_session"
  config.session.domain = "site1.example.com"
end

# Site 2
Panda::CMS.configure do |config|
  config.session.key = "_site2_session"
  config.session.domain = "site2.example.com"
end
```

For more details on configuration organization, see the [Configuration Guide](../configuration/index.md).

## Security Customization

### Password Requirements

If using password authentication alongside OAuth:

```ruby
Panda::CMS.configure do |config|
  config.authentication.password_requirements = {
    minimum_length: 12,
    require_uppercase: true,
    require_lowercase: true,
    require_numbers: true,
    require_symbols: true
  }
end
```

### Two-Factor Authentication

Add 2FA support:

```ruby
Panda::CMS.configure do |config|
  config.authentication.two_factor = {
    enabled: true,
    required_for_roles: ["admin"],
    delivery_method: :email,
    code_validity: 5.minutes
  }
end
```
