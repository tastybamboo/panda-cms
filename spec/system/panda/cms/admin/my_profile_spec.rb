# frozen_string_literal: true

# panda-cms/spec/system/panda/cms/admin/my_profile_spec.rb
require "system_helper"

RSpec.describe "Admin profile management", type: :system do
  fixtures :panda_cms_users

  def ci_wait_time(local: 1, ci: 10)
    ENV["GITHUB_ACTIONS"] ? ci : local
  end

  def ci_long_wait_time(local: 2, ci: 20)
    ENV["GITHUB_ACTIONS"] ? ci : local
  end

  before(:each) do
    login_as_admin

    # Debug CI navigation issues for profile page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Profile test - before navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{page.status_code rescue 'unknown'}"
    end

    begin
      visit "/admin/my_profile/edit"
    rescue => e
      if ENV["GITHUB_ACTIONS"] == "true"
        puts "[CI Debug] Navigation to /admin/my_profile/edit failed: #{e.message}"
        puts "   Current URL after error: #{page.current_url}"
        fail "Profile page navigation failed: #{e.message}"
      else
        raise e
      end
    end

    # Debug CI navigation issues for profile page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Profile test - after navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{page.status_code rescue 'unknown'}"
      puts "   Page content length: #{page.html.length}"
      puts "   Page contains 'My Profile': #{page.html.include?('My Profile')}"
      
      if page.current_url.include?('about:blank') || page.html.length < 100
        puts "   ❌ Profile page didn't load properly"
        puts "   First 500 chars of HTML: #{page.html[0..500]}"
        
        # Check if user is actually logged in
        puts "   Checking login status..."
        begin
          if page.html.include?('Sign in') || page.current_url.include?('login')
            puts "   ❌ User not logged in - redirected to login page"
          else
            puts "   ℹ️ Unknown page state"
          end
        rescue
          puts "   ❌ Could not check login status"
        end
        
        fail "Profile page navigation failed - page didn't load properly"
      end
    end
    
    expect(page.html).to include("My Profile")
    
    # Add extra stability wait in CI environment
    if ENV["GITHUB_ACTIONS"] == "true"
      sleep(1)
    end
  end

  it "displays the profile form with current user information" do
    expect(page.html).to include("My Profile")
    # Wait for form to fully load
    sleep 2
    # Use form field checks that are less prone to node errors
    html_content = page.html
    expect(html_content).to include("First Name")
    expect(html_content).to include("Last Name") 
    expect(html_content).to include("Email Address")
    expect(html_content).to include("Theme")
    expect(html_content).to include("Update Profile")
  end

  it "allows updating profile information", :flaky do
    # Wait for form to be fully ready with all fields (longer waits in CI)
    expect(page).to have_field("First Name", wait: ci_wait_time)
    expect(page).to have_field("Last Name", wait: ci_wait_time)

    fill_in "First Name", with: "Updated"
    fill_in "Last Name", with: "Name"

    # Use normal button click with JavaScript submission
    click_button "Update Profile"

    # Wait for form submission to complete
    sleep 2
    
    # Check if we were redirected to login (session expired)
    if page.has_css?("#button-sign-in-google")
      # Log back in and check the profile was updated
      login_as_admin
      visit "/admin/my_profile/edit"
    end
    
    # Verify the profile values were updated (the main goal)
    expect(page).to have_field("First Name", with: "Updated")
    expect(page).to have_field("Last Name", with: "Name")
  end

  it "allows changing theme preference" do
    # Wait for JavaScript/Stimulus controllers to be ready
    # Use JavaScript evaluation instead of CSS selector to avoid Ferrum issues
    using_wait_time(ci_long_wait_time) do
      theme_form_exists = page.evaluate_script("document.querySelector('[data-controller=\"theme-form\"]') !== null")
      expect(theme_form_exists).to be(true)
    end

    # Wait for Theme select field to be ready (use field ID instead of label)
    expect(page).to have_select("user_current_theme", wait: ci_long_wait_time)

    select "Sky", from: "Theme"

    click_button "Update Profile"

    # Wait a moment for the form submission to process
    sleep(2)

    expect(page.html).to include("Your profile has been updated successfully")
    expect(page).to have_select("Theme", selected: "Sky")

    # Wait for theme to be applied
    using_wait_time(5) do
      expect(page.find("html")["data-theme"]).to eq("sky")
    end
  end

  it "validates required fields", :flaky do
    # Wait for JavaScript/Stimulus controllers to be ready
    # Use JavaScript evaluation instead of CSS selector to avoid Ferrum issues
    using_wait_time(ci_long_wait_time) do
      theme_form_exists = page.evaluate_script("document.querySelector('[data-controller=\"theme-form\"]') !== null")
      expect(theme_form_exists).to be(true)
    end

    # Wait for form fields to be ready (extra long waits for this problematic test)
    expect(page).to have_field("First Name", wait: ci_long_wait_time)
    expect(page).to have_field("Last Name", wait: ci_long_wait_time)
    expect(page).to have_field("Email Address", wait: ci_long_wait_time)

    fill_in "First Name", with: ""
    fill_in "Last Name", with: ""
    fill_in "Email Address", with: ""
    click_button "Update Profile"

    expect(page.html).to include("First Name can't be blank")
    expect(page.html).to include("Last Name can't be blank")
    expect(page.html).to include("Email Address can't be blank")
  end

  it "maintains the selected theme when form submission fails", :flaky do
    # Wait for form fields to be ready (longer waits in CI)
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "[CI Debug] Before looking for First Name field:"
      puts "   Current URL: #{page.current_url rescue 'error'}"
      puts "   Page title: #{page.title rescue 'error'}"
      puts "   Page content length: #{page.html.length rescue 'error'}"
      puts "   Page has 'My Profile': #{page.html.include?('My Profile') rescue 'error'}"
      
      # Ensure we're still on the right page - re-navigate if needed
      if page.current_url.include?('about:blank') || !page.html.include?('My Profile')
        puts "[CI Debug] Page seems to have been reset, re-navigating..."
        visit "/admin/my_profile/edit"
        sleep(1)
      end
    end
    # Use HTML-based checks instead of element finding to avoid browser resets
    expect(page.html).to include('name="user[firstname]"')
    expect(page.html).to include('name="user[current_theme]"')
    
    # Now safely access the form fields using the actual field IDs from HTML
    expect(page).to have_field("user_firstname", wait: ci_wait_time)
    expect(page).to have_select("user_current_theme", wait: ci_wait_time)

    # Use field IDs instead of labels to avoid mismatches
    fill_in "user_firstname", with: ""
    select "Sky", from: "Theme"
    click_button "Update Profile"

    expect(page.html).to include("First Name can't be blank")
    expect(page).to have_select("Theme", selected: "Sky")
  end
end
