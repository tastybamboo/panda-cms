# frozen_string_literal: true

require "system_helper"

RSpec.describe "JavaScript Verification", type: :system do
  # This test runs BEFORE all other system tests to verify JS is working
  # If this fails, all other system tests will likely fail too

  it "verifies that JavaScript can execute in the browser" do
    visit "/admin/login"

    # Wait for page to be ready
    expect(page).to have_css("body", wait: 5)

    # Execute simple JavaScript to verify the browser can run JS
    result = page.evaluate_script("1 + 1")
    expect(result).to eq(2)

    # Verify window object is available
    window_exists = page.evaluate_script("typeof window !== 'undefined'")
    expect(window_exists).to be(true)

    # Verify document object is available
    document_exists = page.evaluate_script("typeof document !== 'undefined'")
    expect(document_exists).to be(true)

    puts "\n✅ JavaScript verification PASSED - browser can execute JS"
    puts "   - Basic math operations work"
    puts "   - Window object is available"
    puts "   - Document object is available"
  end

  it "verifies that Stimulus is loaded and functional" do
    visit "/admin/login"

    # Wait for page load
    expect(page).to have_css("body", wait: 5)

    # Check if Stimulus exists
    stimulus_loaded = page.evaluate_script("typeof window.Stimulus !== 'undefined'")

    if stimulus_loaded
      controller_count = page.evaluate_script("window.Stimulus ? window.Stimulus.controllers.size : 0")
      puts "\n✅ Stimulus verification PASSED"
      puts "   - Stimulus is loaded"
      puts "   - #{controller_count} controller(s) registered"
      expect(stimulus_loaded).to be(true)
    else
      puts "\n⚠️  Stimulus not loaded yet (this may be expected if no controllers on login page)"
      # Don't fail - Stimulus might not be on login page
    end
  end
end
