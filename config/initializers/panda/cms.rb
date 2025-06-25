# frozen_string_literal: true

Panda::CMS.configure do |config|
  # The main title of your website
  config.title = "Demo Site"

  # The path to the administration panel
  config.admin_path = "/admin"

  # Site access control
  config.require_login_to_view = false
end
