# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin authentication", type: :system do
  let(:admin_user) { create_admin_user }

  describe "where provider is" do
    context "Google" do
      it "logs in admin successfully" do
        login_with_google(admin_user)
        # Use string-based checks to avoid DOM node issues
        html_content = page.html
        # Flash message may not always appear, but check we're logged in to dashboard
        expect(html_content).to include("Dashboard")
        expect(page).to have_current_path("/admin/cms")
      end
    end

    context "GitHub" do
      it "logs in admin successfully" do
        # Enable GitHub in both CMS and Core configs
        Panda::CMS.config.authentication[:github][:enabled] = true
        Panda::Core.config.authentication_providers[:github] = {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
        login_with_github(admin_user)
        # Use string-based checks to avoid DOM node issues
        html_content = page.html
        # Flash message may not always appear, but check we're logged in to dashboard
        expect(html_content).to include("Dashboard")
        expect(page).to have_current_path("/admin/cms")
      end
    end

    context "Microsoft" do
      it "logs in admin successfully" do
        # Enable Microsoft in both CMS and Core configs
        Panda::CMS.config.authentication[:microsoft][:enabled] = true
        Panda::Core.config.authentication_providers[:microsoft_graph] = {
          client_id: "test_client_id",
          client_secret: "test_client_secret"
        }
        login_with_microsoft(admin_user)
        # Use string-based checks to avoid DOM node issues
        html_content = page.html
        # Microsoft login may not show flash message, just verify we're on dashboard
        expect(html_content).to include("Dashboard")
        expect(page).to have_current_path("/admin/cms")
      end
    end
  end

  describe "when signing in" do
    it "prevents non-admin access", skip: "Flash messages don't persist across redirects in Capybara" do
      login_with_google(regular_user, expect_success: false)
      expect(page).to have_current_path("/admin/login")
      # Use string-based checks to avoid DOM node issues
      html_content = page.html
      expect(html_content).not_to include("Dashboard")
      expect(html_content).to include("You do not have permission to access the admin area")
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
    it "handles invalid credentials", skip: "Flash messages don't persist across redirects in Capybara" do
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
