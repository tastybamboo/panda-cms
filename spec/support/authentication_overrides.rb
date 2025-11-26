# frozen_string_literal: true

# Override panda-core's test helpers to match the CMS dummy schema (uses is_admin).
module PandaCmsAuthenticationOverrides
  def create_admin_user(attributes = {})
    Panda::Core::User.find_or_create_by!(id: "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a") do |user|
      user.email = attributes[:email] || "admin@test.example.com"
      user.name = attributes[:name] || "Admin User"
      user.admin = true
    end
  end

  def create_regular_user(attributes = {})
    Panda::Core::User.find_or_create_by!(id: "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d") do |user|
      user.email = attributes[:email] || "user@test.example.com"
      user.name = attributes[:name] || "Regular User"
      user.admin = false
    end
  end
end

RSpec.configure do |config|
  config.include PandaCmsAuthenticationOverrides
end
