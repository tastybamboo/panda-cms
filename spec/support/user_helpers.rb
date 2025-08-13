# frozen_string_literal: true

module UserHelpers
  def create_admin_user(attributes = {})
    ensure_columns_loaded
    # Use a fixed ID so fixtures can reference this user
    admin_id = "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a"
    Panda::Core::User.find_or_create_by!(id: admin_id) do |user|
      user.email = attributes[:email] || "admin@example.com"
      user.firstname = attributes[:firstname] || "Admin"
      user.lastname = attributes[:lastname] || "User"
      user.image_url = attributes[:image_url] || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23ccc'/%3E%3C/svg%3E"
      user.admin = attributes.fetch(:admin, true)
    end
  end

  def create_regular_user(attributes = {})
    ensure_columns_loaded
    # Use a fixed ID so fixtures can reference this user
    regular_id = "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d"
    Panda::Core::User.find_or_create_by!(id: regular_id) do |user|
      user.email = attributes[:email] || "user@example.com"
      user.firstname = attributes[:firstname] || "Regular"
      user.lastname = attributes[:lastname] || "User"
      user.image_url = attributes[:image_url] || "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23999'/%3E%3C/svg%3E"
      user.admin = attributes.fetch(:admin, false)
    end
  end

  # Backwards compatibility with fixture access patterns
  def admin_user
    ensure_columns_loaded
    @admin_user ||= Panda::Core::User.find_by(email: "admin@example.com") || create_admin_user
  end

  def regular_user
    ensure_columns_loaded
    @regular_user ||= Panda::Core::User.find_by(email: "user@example.com") || create_regular_user
  end

  private

  def ensure_columns_loaded
    return if @columns_loaded
    Panda::Core::User.connection.schema_cache.clear!
    Panda::Core::User.reset_column_information
    @columns_loaded = true
  end
end

RSpec.configure do |config|
  config.include UserHelpers
end
