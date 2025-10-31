# frozen_string_literal: true

Panda::CMS.configure do |config|
  # The main title of your website
  # The default is "Demo Site"
  config.title = 'Demo Site'
  # Admin path is now configured via Panda::Core
  # config.admin_path = '/admin' # REMOVED - use Panda::Core.config.admin_path instead
  # Is login required to access the site?
  config.require_login_to_view = false
  # Authentication providers
  config.authentication = {
    microsoft: {
      enabled: false,
      # Setup at the following URL:
      # https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade
      client_id: Rails.application.credentials.dig(:microsoft, :client_id),
      client_secret: Rails.application.credentials.dig(:microsoft, :client_secret),
      # Don't change this or the sky will fall on your head
      # https://github.com/synth/omniauth-microsoft_graph/tree/main?tab=readme-ov-file#domain-verification
      skip_domain_verification: false,
      # If your application is single-tenanted, replace "common" with your tenant (directory) ID
      # from https://portal.azure.com/#settings/directory, otherwise you'll likely want to leave
      # these settings unchanged
      client_options: {
        site: 'https://login.microsoftonline.com/',
        token_url: 'common/oauth2/v2.0/token',
        authorize_url: 'common/oauth2/v2.0/authorize'
      },
      # If you assign specific users or groups, you will likely want to set this to true to enable
      # auto-provisioning
      create_account_on_first_login: true
    },
    google: {
      enabled: true,
      create_account_on_first_login: true,
      create_admin_account_on_first_login: false,
      strategy: :google_oauth2
    },
    github: {
      enabled: true,
      create_account_on_first_login: true,
      create_admin_account_on_first_login: false
    }
  }
  # Enable posts
  config.posts = { enabled: true, prefix: 'blog' }
end
