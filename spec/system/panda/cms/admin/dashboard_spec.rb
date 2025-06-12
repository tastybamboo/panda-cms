# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin dashboard", type: :system do
  fixtures :panda_cms_users
  context "when not logged in" do
    it "redirects to login page" do
      visit "/admin"
      expect(page).to have_current_path("/admin")
      expect(page).to_not have_content("Dashboard")
    end
  end

  context "when logged in as regular user" do
    before { login_as_user }

    it "shows 404 error" do
      visit "/admin/dashboard"
      expect(page).to have_content("The page you were looking for doesn't exist")
    end
  end

  context "when logged in as admin" do
    before { login_as_admin }

    it "shows the dashboard" do
      visit "/admin"
      expect(page).to have_content("Dashboard")
    end

    it "displays the admin navigation" do
      visit "/admin"
      expect(page).to have_link("Pages")
      expect(page).to have_link("Posts")
      expect(page).to have_link("Forms")
      expect(page).to have_link("Menus")
      expect(page).to have_link("Settings")
      expect(page).to have_button("Logout")
    end
  end
end
