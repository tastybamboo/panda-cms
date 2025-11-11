# frozen_string_literal: true

require "system_helper"

RSpec.describe "JavaScript errors", type: :system, js: true do
  let(:admin_user) { create_admin_user }

  before do
    login_with_google(admin_user)
  end

  # Helper to check for JavaScript errors
  def check_for_js_errors(page_name)
    # Get console logs via Cuprite
    logs = page.driver.browser.console_messages

    # Filter for errors (level: :error)
    errors = logs.select { |log| log[:level] == :error }

    # Return error messages if any
    error_messages = errors.map { |log| log[:message] }.join("\n")

    expect(error_messages).to be_empty,
      "Expected no JavaScript errors on #{page_name}, but found:\n#{error_messages}"
  end

  describe "Dashboard page" do
    it "has no JavaScript errors on page load" do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard")

      # Wait a moment for any deferred JS to execute
      sleep 1

      check_for_js_errors("Dashboard")
    end

    it "has no JavaScript errors after interaction" do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard")

      # Click around to trigger any lazy-loaded JS
      if page.has_link?("My Profile", wait: 1)
        find("a", text: "My Profile").click
        sleep 0.5
      end

      check_for_js_errors("Dashboard after interaction")
    end
  end

  describe "Pages index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/pages"
      expect(page).to have_content("Pages")

      sleep 1
      check_for_js_errors("Pages index")
    end
  end

  describe "Posts index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/posts"
      expect(page).to have_content("Posts")

      sleep 1
      check_for_js_errors("Posts index")
    end
  end

  describe "Forms index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/forms"
      expect(page).to have_content("Forms")

      sleep 1
      check_for_js_errors("Forms index")
    end
  end

  describe "Files index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/files"
      expect(page).to have_content("Files")

      sleep 1
      check_for_js_errors("Files index")
    end
  end

  describe "Menus index" do
    it "has no JavaScript errors" do
      visit "/admin/cms/menus"
      expect(page).to have_content("Menus")

      sleep 1
      check_for_js_errors("Menus index")
    end
  end

  describe "Settings page" do
    it "has no JavaScript errors" do
      visit "/admin/cms/settings"
      expect(page).to have_content("Settings")

      sleep 1
      check_for_js_errors("Settings page")
    end
  end

  describe "My Profile page" do
    it "has no JavaScript errors" do
      visit "/admin/my_profile"
      expect(page).to have_content("My Profile")

      sleep 1
      check_for_js_errors("My Profile page")
    end
  end

  describe "Navigation interaction" do
    it "has no JavaScript errors when expanding nested menus", js: true do
      visit "/admin/cms"

      # Try to click nested menu items if they exist
      if page.has_button?("Content", wait: 1)
        find("button", text: "Content").click
        sleep 0.5
        check_for_js_errors("After expanding Content menu")
      end

      if page.has_button?("Forms & Files", wait: 1)
        find("button", text: "Forms & Files").click
        sleep 0.5
        check_for_js_errors("After expanding Forms & Files menu")
      end

      if page.has_button?("Tools", wait: 1)
        find("button", text: "Tools").click
        sleep 0.5
        check_for_js_errors("After expanding Tools menu")
      end
    end
  end
end
