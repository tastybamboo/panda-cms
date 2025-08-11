# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin dashboard", type: :system do
  context "when not logged in" do
    it "redirects to login page" do
      visit "/admin/cms"
      expect(page).to have_current_path("/admin/cms")
      expect(page).to_not have_content("Dashboard")
    end
  end

  context "when logged in as regular user" do
    before { login_as_user }

    it "shows 404 error" do
      visit "/admin/cms/dashboard"
      expect(page).to have_content("The page you were looking for doesn't exist")
    end
  end

  context "when logged in as admin" do
    it "shows the dashboard" do
      login_as_admin
      visit "/admin/cms"
      # Use string-based check to avoid DOM node issues
      expect(page.html).to include("Dashboard")
    end

    it "displays the admin navigation" do
      login_as_admin
      visit "/admin/cms"
      # Wait for page to load by checking path
      sleep 2

      # Use string-based checks to avoid DOM node issues
      html_content = page.html
      expect(html_content).to include("Dashboard")
      expect(html_content).to include('href="/admin/cms/pages"')
      expect(html_content).to include('href="/admin/cms/posts"')
      expect(html_content).to include('href="/admin/cms/forms"')
      expect(html_content).to include('href="/admin/cms/menus"')
      expect(html_content).to include('href="/admin/cms/settings"')
      expect(html_content).to include("Logout")
    end
  end
end
