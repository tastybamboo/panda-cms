# Authentication Providers

Panda CMS supports multiple authentication providers through OmniAuth. This guide explains how to configure and use them in your application.

## Available Providers

The following providers are supported out of the box:

- Google (`google_oauth2`)
- Microsoft (`microsoft_graph`)
- GitHub (`github`)

## Configuration

### 1. Install Required Gems

Each provider requires its specific gem. Add the gems for the providers you want to use to your application's Gemfile:

```ruby
# For Google authentication
gem 'omniauth-google-oauth2', '~> 1.1'

# For Microsoft authentication
gem 'omniauth-microsoft_graph', '~> 1.0'

# For GitHub authentication
gem 'omniauth-github', '~> 2.0'
```

### 2. Configure Credentials

Add your provider credentials to your Rails application's encrypted credentials file (`config/credentials.yml.enc`):

```yaml
# For Google
google:
  client_id: your_client_id
  client_secret: your_client_secret
  redirect_uri: https://your-app.com/manage/auth/google/callback

# For Microsoft
microsoft:
  client_id: your_client_id
  client_secret: your_client_secret

# For GitHub
github:
  client_id: your_client_id
  client_secret: your_client_secret
```

### 3. Enable Providers

Configure the providers in your application's initializer (`config/initializers/panda_cms.rb`):

```ruby
Panda::CMS.configure do |config|
  config.authentication = {
    google: {
      enabled: true,
      create_account_on_first_login: true,
      create_admin_account_on_first_login: true,
      prompt: "select_account",
      hd: "yourdomain.com"  # Optional: Restrict to specific domain
    },
    microsoft: {
      enabled: true,
      create_account_on_first_login: false,
      create_admin_account_on_first_login: false
    },
    github: {
      enabled: true,
      create_account_on_first_login: false,
      create_admin_account_on_first_login: false
    }
  }
end
```

## Provider-Specific Setup

### Google

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Go to Credentials
5. Create an OAuth 2.0 Client ID
6. Add authorized redirect URIs:
   - Development: `http://localhost:3000/manage/auth/google/callback`
   - Production: `https://your-app.com/manage/auth/google/callback`

### Microsoft

1. Go to [Azure Portal](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Register a new application
3. Add redirect URIs:
   - Development: `http://localhost:3000/manage/auth/microsoft/callback`
   - Production: `https://your-app.com/manage/auth/microsoft/callback`
4. Note your client ID and generate a client secret

### GitHub

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App
3. Add callback URLs:
   - Development: `http://localhost:3000/manage/auth/github/callback`
   - Production: `https://your-app.com/manage/auth/github/callback`
4. Note your client ID and generate a client secret

## Troubleshooting

### Common Issues

1. **Missing Gem Error**
   ```
   The google authentication provider requires the omniauth-google-oauth2 gem
   ```
   Solution: Add the required gem to your Gemfile and run `bundle install`

2. **Missing Credentials Error**
   ```
   Missing credentials for google authentication provider
   ```
   Solution: Add the required credentials to your `credentials.yml.enc` file

3. **Invalid Configuration Error**
   ```
   Invalid configuration for google authentication provider: Strategy not found
   ```
   Solution: Ensure you have the correct gem installed and the configuration matches the provider's requirements

### Debug Logging

Authentication-related logs can be found in your Rails application logs. The engine uses Rails.logger for all authentication-related messages.

## Security Considerations

1. Always use HTTPS in production
2. Keep your client secrets secure
3. Use domain restrictions where appropriate (e.g., Google's `hd` option)
4. Consider enabling `create_account_on_first_login` only during initial setup

## Advanced Configuration

### Custom Provider Settings

Each provider supports additional configuration options. Refer to each provider's gem documentation for available options:

- [omniauth-google-oauth2](https://github.com/zquestz/omniauth-google-oauth2)
- [omniauth-microsoft_graph](https://github.com/synth/omniauth-microsoft_graph)
- [omniauth-github](https://github.com/omniauth/omniauth-github)

### Auto-Provisioning

The `create_account_on_first_login` and `create_admin_account_on_first_login` options control user provisioning:

```ruby
config.authentication = {
  google: {
    enabled: true,
    create_account_on_first_login: true,     # Create regular user accounts
    create_admin_account_on_first_login: true # Create admin accounts
  }
}
```

### Custom Callback URLs

By default, callbacks use the pattern `/manage/auth/:provider/callback`. You can customize this by setting `Panda::CMS.config.url` in your application configuration.
