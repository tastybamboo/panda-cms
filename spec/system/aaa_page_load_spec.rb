# frozen_string_literal: true

require "system_helper"

RSpec.describe "Page Load Test", type: :system do
  # This test runs early (aaa_ prefix) to test if Chrome can load actual pages
  # If this passes, Chrome is fine and the issue is specific to certain pages/features
  # If this fails, the issue is with page loading or JavaScript/assets in general

  it "can visit the login page without crashing" do
    puts "\n[Page Load] Testing if Chrome can visit the login page..."
    puts "[Page Load] This tests if Chrome crashes when loading:"
    puts "[Page Load]   - JavaScript assets"
    puts "[Page Load]   - CSS assets"
    puts "[Page Load]   - Importmap configuration"

    begin
      visit "/panda/cms/admin/login"
      puts "\n✅ Page load PASSED - Chrome loaded the login page"
      puts "   Page title: #{page.title}"
      expect(page).to have_current_path("/panda/cms/admin/login")
    rescue => e
      puts "\n❌ Page load FAILED - Chrome crashed loading the page"
      puts "   Error: #{e.class}: #{e.message}"
      raise
    end
  end

  it "can visit the root page without crashing" do
    puts "\n[Page Load] Testing if Chrome can visit the root page..."

    begin
      visit "/"
      puts "\n✅ Root page load PASSED"
      puts "   Status code: #{page.status_code}"
      expect([200, 404]).to include(page.status_code)
    rescue => e
      puts "\n❌ Root page load FAILED"
      puts "   Error: #{e.class}: #{e.message}"
      raise
    end
  end
end
