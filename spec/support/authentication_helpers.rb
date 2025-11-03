# frozen_string_literal: true

module AuthenticationHelpers
  # Creates an admin user for testing
  # Uses fixed ID for consistent references in fixtures
  def create_admin_user
    Panda::Core::User.find_or_create_by(id: "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a") do |user|
      user.email = "admin@example.com"
      user.firstname = "Admin"
      user.lastname = "User"
      user.admin = true
    end
  end

  # Creates a regular (non-admin) user for testing
  # Uses fixed ID for consistent references in fixtures
  def create_regular_user
    Panda::Core::User.find_or_create_by(id: "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d") do |user|
      user.email = "user@example.com"
      user.firstname = "Regular"
      user.lastname = "User"
      user.admin = false
    end
  end

  # Logs in as an admin user in system tests
  def login_as_admin
    admin = create_admin_user
    OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new({
      provider: "developer",
      uid: admin.id,
      info: {
        email: admin.email,
        name: admin.name
      }
    })
    visit "/admin/auth/developer/callback"
    admin
  end

  # Logs in as a regular user in system tests
  def login_as_user
    user = create_regular_user
    OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new({
      provider: "developer",
      uid: user.id,
      info: {
        email: user.email,
        name: user.name
      }
    })
    visit "/admin/auth/developer/callback"
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
