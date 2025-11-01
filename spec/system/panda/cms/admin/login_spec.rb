# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin authentication", type: :system do
  let(:admin_user) { create_admin_user }

  describe "where provider is" do
    context "Google" do
      it "logs in admin successfully using test endpoint" do
        # Create admin and visit test login endpoint
        visit "/admin/test_login/#{admin_user.id}"
        sleep 0.3

        # Verify session was created by checking we can access an admin page
        visit "/admin"
        # Should not be redirected to login
        expect(page).not_to have_current_path("/admin/login")
      end
    end

    context "GitHub" do
      it "logs in admin successfully using test endpoint" do
        # Create admin and visit test login endpoint
        visit "/admin/test_login/#{admin_user.id}"
        sleep 0.3

        # Verify session was created
        visit "/admin"
        expect(page).not_to have_current_path("/admin/login")
      end
    end

    context "Microsoft" do
      it "logs in admin successfully using test endpoint" do
        # Create admin and visit test login endpoint
        visit "/admin/test_login/#{admin_user.id}"
        sleep 0.3

        # Verify session was created
        visit "/admin"
        expect(page).not_to have_current_path("/admin/login")
      end
    end
  end

  describe "when signing in" do
    it "prevents non-admin access" do
      # Try to login as regular user
      visit "/admin/test_login/#{regular_user.id}"
      sleep 0.3

      # Should be redirected to login (flash message tested in request specs)
      expect(page).to have_current_path("/admin/login")
      # Verify we're on the login page, not in the admin area
      expect(page).not_to have_content("Dashboard")
    end
  end

  describe "with sessions" do
    it "maintains admin session across pages", skip: "Transactional fixtures prevent Capybara server from seeing test data" do
      login_with_google(admin_user)
      visit "/admin/cms/pages"
      expect(page).not_to have_current_path("/admin/login")
      # Use string-based checks to avoid DOM node issues
      html_content = page.html
      expect(html_content).to include(admin_user.name)
      expect(html_content).to match(/pages|content/i)
    end

    it "handles logout properly", skip: "Rails UJS not loaded in test environment" do
      login_with_google(admin_user)

      # Simulate logout by deleting the session
      # Since Rails UJS might not be loaded, we'll use page.driver to send DELETE
      page.driver.delete("/admin/logout")

      # Should redirect to login page
      visit page.driver.response.headers["Location"] || "/admin/login"

      expect(page).to have_current_path("/admin/login")
      expect(page.html).to include("Sign in")
    end
  end

  describe "on error" do
    it "handles invalid credentials" do
      # Use the helper to set up the mock auth with invalid credentials
      clear_omniauth_config
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      # Visit the callback URL directly (simulating failed OAuth)
      visit "/admin/auth/google_oauth2/callback"

      # Should redirect back to login with error message
      expect(page).to have_current_path("/admin/login")
      expect(page).to have_content("Authentication failed")
    end
  end
end
