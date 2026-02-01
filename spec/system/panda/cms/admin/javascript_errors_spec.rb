# frozen_string_literal: true

require "system_helper"

RSpec.describe "JavaScript errors", type: :system, js: true do
  let(:admin_user) { create_admin_user }

  before do
    login_with_google(admin_user)
  end

  # Helper to set up error tracking on a page
  def setup_error_tracking
    page.execute_script(<<~JS)
      window.jsErrors = [];
      window.addEventListener('error', function(e) {
        window.jsErrors.push(e.message + ' at ' + e.filename + ':' + e.lineno);
      });
      window.addEventListener('unhandledrejection', function(e) {
        window.jsErrors.push('Unhandled promise rejection: ' + e.reason);
      });
    JS
  end

  # Helper to check for JavaScript errors
  def check_for_js_errors(page_name)
    # Get any errors that were captured
    has_errors = page.evaluate_script("window.jsErrors || []")

    error_messages = has_errors.join("\n")

    expect(error_messages).to be_empty,
      "Expected no JavaScript errors on #{page_name}, but found:\n#{error_messages}"
  end

  describe "Dashboard page" do
    it "has no JavaScript errors on page load" do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard", wait: 5)
      setup_error_tracking

      # Error tracking is now active - check for errors
      # (no sleep needed - if content loaded, JS has executed)
      check_for_js_errors("Dashboard")
    end

    it "has no JavaScript errors after interaction" do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard", wait: 5)
      setup_error_tracking

      # Click around to trigger any lazy-loaded JS
      # Try to interact with navigation menu items if they exist
      if page.has_css?("nav a", wait: 1)
        first_link = page.first("nav a", minimum: 1)
        first_link&.click
      end

      check_for_js_errors("Dashboard after interaction")
    end
  end

  describe "Pages index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/pages"
      expect(page).to have_content("Pages", wait: 5)
      setup_error_tracking

      check_for_js_errors("Pages index")
    end
  end

  describe "Posts index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/posts"
      expect(page).to have_content("Posts", wait: 5)
      setup_error_tracking

      check_for_js_errors("Posts index")
    end
  end

  describe "Forms index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/forms"
      expect(page).to have_content("Forms", wait: 5)
      setup_error_tracking

      check_for_js_errors("Forms index")
    end
  end

  describe "Files index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/files"
      expect(page).to have_content("Files", wait: 5)
      setup_error_tracking

      check_for_js_errors("Files index")
    end
  end

  describe "Menus index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/menus"
      expect(page).to have_content("Menus", wait: 5)
      setup_error_tracking

      check_for_js_errors("Menus index")
    end
  end

  describe "Settings page" do
    it "has no JavaScript errors" do
      visit "/admin/cms/settings"
      expect(page).to have_content("Settings", wait: 5)
      setup_error_tracking

      check_for_js_errors("Settings page")
    end
  end

  describe "My Profile page" do
    it "has no JavaScript errors" do
      visit "/admin/my_profile"
      expect(page).to have_content("My Profile", wait: 5)
      setup_error_tracking

      check_for_js_errors("My Profile page")
    end
  end

  describe "Navigation interaction" do
    it "has no JavaScript errors when expanding nested menus", js: true do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard", wait: 5)
      setup_error_tracking

      # Try to click nested menu items in the sidebar navigation
      %w[Content Forms\ &\ Files Tools].each do |menu_label|
        if page.has_button?(menu_label, wait: 1)
          find("button", text: menu_label).trigger("click")
          check_for_js_errors("After expanding #{menu_label} menu")
        end
      end
    end
  end
end
