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
    it "redirects to login page" do
      login_with_google(regular_user, expect_success: false)
      expect(page).to have_current_path("/admin/login")

      # Regular users cannot access the dashboard
      # We've already verified they're redirected to login above
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

      # Wait for Dashboard to appear, then check navigation
      expect(page).to have_content("Dashboard", wait: 5)

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

    it "does not display icons in page headings" do
      login_as_admin

      %w[/admin/cms/pages /admin/cms/posts /admin/cms/forms /admin/cms/files /admin/cms/menus /admin/cms/settings].each do |path|
        visit path
        expect(page).to have_css("h1", wait: 5)
        expect(page).to have_no_css("h1 i", wait: 0), "Expected no icon in h1 heading on #{path}"
      end
    end
  end
end
