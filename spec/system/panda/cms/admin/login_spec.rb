# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin authentication", type: :system do
  fixtures :panda_cms_users
  describe "where provider is" do
    context "Google" do
      it "logs in admin successfully" do
        login_with_google(admin_user)
        expect(page).to have_content("You are logged in!")
        expect(page).to have_content("Dashboard")
      end
    end

    context "GitHub" do
      it "logs in admin successfully" do
        Panda::CMS.config.authentication[:github][:enabled] = true
        login_with_github(admin_user)
        expect(page).to have_content("You are logged in!")
        expect(page).to have_content("Dashboard")
      end
    end

    context "Microsoft" do
      it "logs in admin successfully" do
        Panda::CMS.config.authentication[:microsoft][:enabled] = true
        login_with_microsoft(admin_user)
        expect(page).to have_content("You are logged in!")
        expect(page).to have_content("Dashboard")
      end
    end
  end

  describe "when signing in" do
    it "prevents non-admin access" do
      login_with_google(regular_user)
      expect(page).to have_current_path("/admin")
      expect(page).to_not have_content("Dashboard")
      expect(page).to have_content("There was an error logging you in")
    end
  end

  describe "with sessions" do
    it "maintains admin session across pages" do
      login_with_google(admin_user)
      visit "/admin/pages"
      expect(page).not_to have_current_path("/admin/login")
      expect(page).to have_content(admin_user.name)
      expect(page).to have_content(/pages|content/i)
    end

    it "handles logout properly" do
      login_with_google(admin_user)
      click_on id: "logout-link"
      expect(page).to have_current_path("/admin")
      expect(page).to have_content("Sign in to your account")
    end
  end

  describe "on error" do
    it "handles invalid credentials" do
      # Initialize the authentication config hash if it doesn't exist
      OmniAuth.config.mock_auth[:google] = :invalid_credentials
      visit "/admin"

      # Add debugging and wait for page load
      expect(page).to have_current_path("/admin")
      expect(page).to have_selector("#button-sign-in-google", wait: 1)

      find("#button-sign-in-google").click
      expect(page).to have_current_path("/admin")
      expect(page).to have_content("There was an error logging you in")
    end
  end
end
