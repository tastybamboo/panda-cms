# Testing Authentication

This guide covers how to test authentication in your Panda CMS application.

## Helper Methods

Panda CMS provides helper methods for authentication in your tests:

```ruby
# Log in as an admin user
login_as_admin

# Log in as a regular user
login_as_user

# Log in as a specific user
login_as(user)
```

## System Tests

For system tests, use these helpers in your `before` blocks:

```ruby
require "system_helper"

RSpec.describe "Admin Panel", type: :system do
  context "when logged in as admin" do
    before do
      login_as_admin
    end

    it "shows the admin dashboard" do
      visit "/manage"
      expect(page).to have_content("Dashboard")
    end
  end

  context "when logged in as regular user" do
    before do
      login_as_user
    end

    it "shows access denied" do
      visit "/manage"
      expect(page).to have_content("The page you were looking for doesn't exist")
    end
  end
end
```

## Testing Different Providers

### Mock Authentication

For testing with specific providers, you can mock the OmniAuth response:

```ruby
# spec/support/omniauth_helpers.rb
module OmniAuthHelpers
  def mock_google_auth(email: "user@example.com", name: "Test User")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: email,
        name: name
      },
      credentials: {
        token: "mock_token",
        expires_at: 1.week.from_now.to_i
      }
    })
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers, type: :system
end
```

### Example Test Cases

```ruby
RSpec.describe "Authentication", type: :system do
  before do
    # Ensure OmniAuth is in test mode
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  it "allows Google login for allowed domain" do
    mock_google_auth(email: "user@allowed-domain.com")
    visit "/manage/login"
    click_link "Sign in with Google"
    expect(page).to have_content("Successfully authenticated")
  end

  it "prevents login from unauthorized domain" do
    mock_google_auth(email: "user@unauthorized-domain.com")
    visit "/manage/login"
    click_link "Sign in with Google"
    expect(page).to have_content("Access denied")
  end
end
```

## Testing Auto-Provisioning

Test how your application handles new users:

```ruby
RSpec.describe "User Provisioning", type: :system do
  context "with auto-provisioning enabled" do
    before do
      allow(Panda::CMS.config.authentication.google)
        .to receive(:create_account_on_first_login)
        .and_return(true)
    end

    it "creates new user account on first login" do
      mock_google_auth(email: "new@example.com")
      expect {
        visit "/manage/login"
        click_link "Sign in with Google"
      }.to change(User, :count).by(1)
    end
  end

  context "with auto-provisioning disabled" do
    before do
      allow(Panda::CMS.config.authentication.google)
        .to receive(:create_account_on_first_login)
        .and_return(false)
    end

    it "does not create new user account" do
      mock_google_auth(email: "new@example.com")
      expect {
        visit "/manage/login"
        click_link "Sign in with Google"
      }.not_to change(User, :count)
    end
  end
end
```

## Testing Environment Configuration

### Test Environment Setup

In your `config/environments/test.rb`:

```ruby
Rails.application.configure do
  # Configure test mode for OmniAuth
  OmniAuth.config.test_mode = true

  # Disable request forgery protection in test environment
  OmniAuth.config.allowed_request_methods = [:get, :post]
end
```

### Example Configuration Test

```ruby
RSpec.describe "Authentication Configuration", type: :system do
  it "loads correct provider configuration" do
    config = Panda::CMS.config.authentication
    expect(config.google.enabled).to be_in([true, false])
    expect(config.google.client_id).to be_present if config.google.enabled
  end
end
```

## Debugging Tips

1. Enable detailed OmniAuth logging in test:
```ruby
OmniAuth.config.logger = Rails.logger
Rails.logger.level = :debug
```

2. Check authentication flow with `puts_debug`:
```ruby
puts_debug "Auth Hash: #{auth_hash.inspect}"
puts_debug "Session: #{session.inspect}"
```

3. Monitor authentication events:
```ruby
ActiveSupport::Notifications.subscribe("omniauth.auth") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  puts_debug "Auth Event: #{event.payload.inspect}"
end
```
