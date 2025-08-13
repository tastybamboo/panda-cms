# frozen_string_literal: true

Panda::CMS.configure do |config|
  # The main title of your website
  config.title = "Demo Site"

  # Site access control
  config.require_login_to_view = false
end

# Admin path is now configured via Panda::Core
Panda::Core.configure do |config|
  # The path to the administration panel
  config.admin_path = "/admin"
end
