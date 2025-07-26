# frozen_string_literal: true

require "system_helper"

RSpec.describe "Ferrum NodeNotFoundError Debug", type: :system do
  it "demonstrates the browser context issue" do
    puts "\n[DEBUG] Starting Ferrum debug test"
    puts "[DEBUG] Current URL before visit: #{page.current_url rescue 'error'}"
    
    # Visit a simple page
    visit "/admin/login"
    puts "[DEBUG] Current URL after visit: #{page.current_url}"
    
    # Try to find an element
    begin
      puts "[DEBUG] Looking for body element..."
      body = page.find("body")
      puts "[DEBUG] Found body element"
      
      # Try to interact with a form field
      puts "[DEBUG] Looking for login form..."
      if page.has_css?("#button-sign-in-google", wait: 2)
        puts "[DEBUG] Found login button"
      else
        puts "[DEBUG] Login button not found"
      end
      
      # Try JavaScript execution
      puts "[DEBUG] Testing JavaScript execution..."
      result = page.evaluate_script("1 + 1")
      puts "[DEBUG] JavaScript result: #{result}"
      
      # Check window properties
      window_info = page.evaluate_script(<<~JS)
        {
          url: window.location.href,
          title: document.title,
          readyState: document.readyState,
          bodyExists: !!document.body
        }
      JS
      puts "[DEBUG] Window info: #{window_info.inspect}"
      
    rescue Ferrum::NodeNotFoundError => e
      puts "[DEBUG] NodeNotFoundError: #{e.message}"
      puts "[DEBUG] Current URL when error occurred: #{page.current_url rescue 'error'}"
      puts "[DEBUG] Page HTML length: #{page.html.length rescue 'error'}"
      raise
    rescue => e
      puts "[DEBUG] Other error: #{e.class} - #{e.message}"
      raise
    end
    
    puts "[DEBUG] Test completed successfully"
  end
  
  it "tests simple element interaction" do
    visit "/admin/login"
    
    # This should work with proper retry handling
    expect(page).to have_css("body")
    expect(page).to have_content("Sign in")
  end
end