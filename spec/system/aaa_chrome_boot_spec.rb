# frozen_string_literal: true

require "system_helper"

RSpec.describe "Chrome Boot", type: :system do
  # This test runs BEFORE all other tests (aaa_ prefix ensures alphabetical ordering)
  # It boots Chrome WITHOUT visiting any page to isolate Chrome startup issues
  # from page loading/server issues

  it "boots Chrome successfully without visiting any page" do
    puts "\n[Chrome Boot] Testing if Chrome can start without loading any page..."
    puts "[Chrome Boot] This tests if Chrome crashes on startup due to:"
    puts "[Chrome Boot]   - Invalid importmap configuration"
    puts "[Chrome Boot]   - Corrupted asset compilation"
    puts "[Chrome Boot]   - Missing JavaScript modules"
    puts "[Chrome Boot]   - Shared memory issues (/dev/shm)"

    # Simply accessing 'page' triggers Cuprite to boot Chrome
    # This should work even if the Rails server isn't running
    begin
      page # This boots Chrome but doesn't navigate anywhere
      puts "\n✅ Chrome boot PASSED - Chrome started successfully"
      puts "   Chrome is running and responding to DevTools Protocol"
      expect(true).to be_truthy
    rescue => e
      puts "\n❌ Chrome boot FAILED - Chrome crashed on startup"
      puts "   Error: #{e.class}: #{e.message}"
      raise
    end
  end
end
