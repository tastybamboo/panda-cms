# Test Writing Guide for Panda CMS

## Overview

This guide explains how to write tests for Panda CMS after the user migration to panda-core. Since users are now managed by the panda-core gem, we use programmatic user creation instead of fixtures.

## Key Changes from Traditional Rails Testing

1. **No User Fixtures**: User fixtures (`panda_core_users`) are NOT loaded globally
2. **No Post Fixtures**: Post fixtures (`panda_cms_posts`) are NOT loaded globally (they require users)
3. **Programmatic User Creation**: Users are created on-demand using helper methods
4. **Fixed User IDs**: Helper methods use consistent IDs for reliable references

## User Creation Helpers

We provide two helper methods in `spec/support/user_helpers.rb`:

```ruby
# Creates an admin user with a fixed ID
admin = create_admin_user

# Creates a regular user with a fixed ID  
user = create_regular_user

# You can override attributes
custom_admin = create_admin_user(
  email: "custom@example.com",
  firstname: "Custom",
  lastname: "Admin"
)
```

### Fixed IDs for Reference

The helper methods use fixed UUIDs so you can reference them in fixtures or other code:
- Admin user ID: `8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a`
- Regular user ID: `9a8b7c6d-5e4f-3a2b-1c0d-9e8f7a6b5c4d`

## Writing Different Types of Tests

### Model Tests

Model tests should create users as needed:

```ruby
RSpec.describe YourModel, type: :model do
  describe "associations" do
    it "belongs to a user" do
      user = create_admin_user
      model = YourModel.create!(user: user, other_attributes: "...")
      expect(model.user).to eq(user)
    end
  end
end
```

### System Tests

System tests should create users before logging in:

```ruby
RSpec.describe "Your Feature", type: :system do
  before do
    # Create users first
    @admin = create_admin_user
    @regular = create_regular_user
    
    # Then login
    login_as_admin
  end
  
  it "does something" do
    visit "/admin/something"
    # ... test implementation
  end
end
```

### Tests with Posts or Other User-Dependent Models

When testing models that depend on users (like posts), create them programmatically:

```ruby
RSpec.describe "Post Management", type: :system do
  before do
    # Create users first
    @admin = create_admin_user
    
    # Create posts programmatically
    @post = Panda::CMS::Post.create!(
      title: "Test Post",
      slug: "/test-post",
      user: @admin,
      author: @admin,
      status: "active",
      content: { "blocks" => [] },
      cached_content: "<p>Test</p>"
    )
    
    login_as_admin
  end
  
  it "edits the post" do
    visit "/admin/posts/#{@post.id}/edit"
    # ... test implementation
  end
end
```

### Using Fixtures That Reference Users

If you have fixtures that need to reference users, use the fixed IDs:

```yaml
# spec/fixtures/your_model.yml
example_record:
  title: "Example"
  user_id: "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a" # admin_user fixed ID
  author_id: "8f481fcb-d9c8-55d7-ba17-5ea5d9ed8b7a" # admin_user fixed ID
```

Then ensure users exist before the fixtures are used:

```ruby
RSpec.describe "Your Test", type: :system do
  fixtures :your_model
  
  before do
    # Create users that fixtures expect
    create_admin_user
    create_regular_user
  end
  
  # ... tests
end
```

## Important Database Columns

The Panda::Core::User model uses these database columns:
- `firstname` (not `name`)
- `lastname` (not `name`)  
- `admin` (not `is_admin`)
- `email`
- `image_url`

The model provides a `name` method that returns `"#{firstname} #{lastname}"`.

## Fixture Configuration

In `spec/rails_helper.rb`, we exclude user and post fixtures from global loading:

```ruby
fixture_files = Dir[File.expand_path("fixtures/*.yml", __dir__)].map do |f|
  File.basename(f, ".yml").to_sym
end
fixture_files.delete(:panda_core_users)  # Users created programmatically
fixture_files.delete(:panda_cms_posts)   # Posts require users
config.global_fixtures = fixture_files
```

## Common Patterns

### Pattern 1: Test Requiring Admin User

```ruby
before do
  @admin = create_admin_user
  login_as_admin
end
```

### Pattern 2: Test Requiring Multiple Users

```ruby
before do
  @admin = create_admin_user
  @editor = create_regular_user(email: "editor@example.com")
  @viewer = create_regular_user(email: "viewer@example.com")
end
```

### Pattern 3: Test with User-Owned Resources

```ruby
before do
  @user = create_admin_user
  @resource = Model.create!(
    user: @user,
    # other attributes
  )
end
```

## Troubleshooting

### "undefined method 'name=' for Panda::Core::User"

You're trying to set `name` but the columns are `firstname` and `lastname`:

```ruby
# Wrong
user = Panda::Core::User.create!(name: "John Doe", ...)

# Correct  
user = Panda::Core::User.create!(firstname: "John", lastname: "Doe", ...)
```

### "Foreign key violation" errors

This happens when fixtures try to reference users that don't exist. Either:
1. Remove the fixture from global loading
2. Create users before the fixture loads
3. Convert the fixture to programmatic creation

### "undefined method 'is_admin' for User"

The column is `admin`, not `is_admin`:

```ruby
# Wrong
if user.is_admin

# Correct
if user.admin?  # Use the method
if user.admin   # Or access the column directly
```

## Best Practices

1. **Always create users first** in your test setup
2. **Use the helper methods** instead of creating users manually
3. **Don't rely on fixtures** for user-dependent data
4. **Create resources programmatically** when they depend on users
5. **Use fixed IDs** when you need consistent references
6. **Login after creating users** in system tests

## Migration Notes

This approach was chosen (option #3 from the migration plan) to:
- Avoid Rails fixture loading issues with engine models
- Provide flexibility in test data creation
- Ensure consistent test behavior
- Work around Rails column caching problems

The alternative approaches (modifying migrations or using aliases) had significant drawbacks that made them unsuitable for a sustainable testing strategy.