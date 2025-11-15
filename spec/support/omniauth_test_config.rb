# frozen_string_literal: true

# CMS-specific OmniAuth configuration
# Generic OmniAuth test setup is provided by panda-core's authentication_test_helpers.rb
# This file contains only CMS-specific provider configuration

# Configure Panda CMS authentication providers
Panda::CMS.configure do |config|
  config.authentication = {
    google: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    },
    microsoft: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    },
    github: {
      enabled: true,
      client_id: "test_id",
      client_secret: "test_secret",
      create_account_on_first_login: true
    }
  }
end
