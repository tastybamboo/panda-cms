# frozen_string_literal: true

# This file ensures that users are created before fixtures are loaded
# Since panda_core_users are in a separate gem, we need to create them programmatically
# before fixtures that reference them are loaded

RSpec.configure do |config|
  config.before(:suite) do
    # Ensure the test database is ready
    ActiveRecord::Base.connection.schema_cache.clear!
    
    # Create users with fixed IDs that match what the fixtures expect
    # These IDs are referenced in panda_cms_posts.yml fixtures
    admin_id = "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a"
    regular_id = "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d"
    
    # Reset column information to ensure we have the latest schema
    Panda::Core::User.reset_column_information
    
    # Create admin user if it doesn't exist
    unless Panda::Core::User.exists?(id: admin_id)
      Panda::Core::User.create!(
        id: admin_id,
        email: "admin@example.com",
        firstname: "Admin",
        lastname: "User",
        image_url: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23ccc'/%3E%3C/svg%3E",
        admin: true
      )
    end
    
    # Create regular user if it doesn't exist
    unless Panda::Core::User.exists?(id: regular_id)
      Panda::Core::User.create!(
        id: regular_id,
        email: "user@example.com",
        firstname: "Regular",
        lastname: "User",
        image_url: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100' height='100' fill='%23999'/%3E%3C/svg%3E",
        admin: false
      )
    end
  end
  
  config.after(:suite) do
    # Clean up users after all tests
    Panda::Core::User.where(id: ["8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a", "9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d"]).destroy_all
  end
end