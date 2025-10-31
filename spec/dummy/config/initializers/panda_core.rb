# frozen_string_literal: true

# Configure Panda Core authentication
Panda::Core.configure do |config|
  # Customize branding for CMS dummy app
  config.login_logo_path = "/panda-cms-assets/panda-nav.png"
  config.login_page_title = "Panda CMS"

  # Set up authentication providers from CMS config
  cms_auth = Panda::CMS.config.authentication || {}

  config.authentication_providers = {}
  
  # Microsoft authentication
  if cms_auth.dig(:microsoft, :enabled)
    config.authentication_providers[:microsoft_graph] = {
      client_id: cms_auth.dig(:microsoft, :client_id),
      client_secret: cms_auth.dig(:microsoft, :client_secret),
      options: {
        skip_domain_verification: cms_auth.dig(:microsoft, :skip_domain_verification),
        client_options: cms_auth.dig(:microsoft, :client_options)
      }.compact
    }
  end
  
  # Google authentication
  if cms_auth.dig(:google, :enabled)
    config.authentication_providers[:google_oauth2] = {
      client_id: Rails.application.credentials.dig(:google, :client_id) || "test_client_id",
      client_secret: Rails.application.credentials.dig(:google, :client_secret) || "test_client_secret",
      options: {}
    }
  end
  
  # GitHub authentication
  if cms_auth.dig(:github, :enabled)
    config.authentication_providers[:github] = {
      client_id: Rails.application.credentials.dig(:github, :client_id) || "test_client_id",
      client_secret: Rails.application.credentials.dig(:github, :client_secret) || "test_client_secret",
      options: {}
    }
  end
end