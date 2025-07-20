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

    puts "[DEBUG] About to visit profile page after login" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path before profile visit: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Session cookies: #{page.driver.browser.cookies.all.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    profile_path = panda_cms.edit_admin_my_profile_path
    puts "[DEBUG] Profile path resolved to: #{profile_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    visit profile_path

    puts "[DEBUG] After profile visit - Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After profile visit - Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After profile visit - Page title: #{page.title}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
  end

  it "displays the profile form with current user information" do
    puts "[DEBUG] === STARTING TEST: displays the profile form with current user information ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Starting test assertions - checking page state" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Debug actual page content to see what's missing
    puts "[DEBUG] Looking for 'My Profile' in page..." if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    if page.has_content?("My Profile", wait: 0)
      puts "[DEBUG] 'My Profile' found!" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    else
      puts "[DEBUG] 'My Profile' NOT found. Text content length: #{page.text.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    end

    expect(page).to have_content("My Profile")
    puts "[DEBUG] Found 'My Profile' content" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    expect(page).to have_field("First Name")
    puts "[DEBUG] Found 'First Name' field" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    expect(page).to have_field("Last Name")
    expect(page).to have_field("Email Address")
    expect(page).to have_field("Theme")
    expect(page).to have_button("Update Profile")
    puts "[DEBUG] All form elements found successfully" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
  end

  it "allows updating profile information" do
    puts "[DEBUG] === STARTING TEST: allows updating profile information ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Starting profile update test" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path before form interaction: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait for form to be fully ready with all fields (longer waits in CI)
    expect(page).to have_field("First Name", wait: ci_wait_time)
    expect(page).to have_field("Last Name", wait: ci_wait_time)

    puts "[DEBUG] Form fields are ready" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    fill_in "First Name", with: "Updated"
    puts "[DEBUG] Filled First Name field" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    fill_in "Last Name", with: "Name"
    puts "[DEBUG] Filled Last Name field" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    puts "[DEBUG] About to click Update Profile button" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path before button click: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    click_button "Update Profile"

    puts "[DEBUG] After button click - Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After button click - Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_field("First Name", with: "Updated")
    expect(page).to have_field("Last Name", with: "Name")
  end

  it "allows changing theme preference" do
    puts "[DEBUG] === STARTING TEST: allows changing theme preference ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path at start: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page content length at start: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait for JavaScript/Stimulus controllers to be ready
    puts "[DEBUG] Waiting for Stimulus controller..." if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    expect(page).to have_css('[data-controller="theme-form"]', wait: ci_long_wait_time)
    puts "[DEBUG] Stimulus controller found" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait for Theme select field to be ready (extra long waits for this problematic field)
    puts "[DEBUG] Waiting for Theme select field..." if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    expect(page).to have_select("Theme", wait: ci_long_wait_time)
    puts "[DEBUG] Theme select field is ready" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    puts "[DEBUG] About to select Sky from Theme" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    select "Sky", from: "Theme"
    puts "[DEBUG] Selected Sky from Theme" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    puts "[DEBUG] About to submit form - Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] About to submit form - Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Debug form details before submission
    if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
      form = page.find('form[data-controller="theme-form"]')
      puts "[DEBUG] Form action: #{form[:action]}"
      puts "[DEBUG] Form method: #{form[:method]}"
      puts "[DEBUG] Form data-controller: #{form[:'data-controller']}"
      csrf_token = page.find('input[name="authenticity_token"]', visible: false)[:value] rescue "Not found"
      puts "[DEBUG] CSRF token present: #{csrf_token != 'Not found'}"
    end

    click_button "Update Profile"
    puts "[DEBUG] Clicked Update Profile button" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait a moment for the form submission to process
    sleep(2)

    puts "[DEBUG] After form submission - Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After form submission - Current URL: #{page.current_url}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After form submission - Page title: #{page.title}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After form submission - Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] After form submission - Response status: #{page.status_code}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Check if we're on a blank page
    if page.html.length < 100
      puts "[DEBUG] BLANK PAGE DETECTED after form submission!" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
      puts "[DEBUG] Page HTML: #{page.html}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    end

    puts "[DEBUG] Looking for success message..." if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page text contains: #{page.text[0..200]}..." if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_select("Theme", selected: "Sky")

    # Wait for theme to be applied
    using_wait_time(5) do
      expect(page.find("html")["data-theme"]).to eq("sky")
    end
  end

  it "validates required fields" do
    puts "[DEBUG] === STARTING TEST: validates required fields ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait for JavaScript/Stimulus controllers to be ready
    expect(page).to have_css('[data-controller="theme-form"]', wait: ci_long_wait_time)

    # Wait for form fields to be ready (extra long waits for this problematic test)
    expect(page).to have_field("First Name", wait: ci_long_wait_time)
    expect(page).to have_field("Last Name", wait: ci_long_wait_time)
    expect(page).to have_field("Email Address", wait: ci_long_wait_time)

    fill_in "First Name", with: ""
    fill_in "Last Name", with: ""
    fill_in "Email Address", with: ""
    click_button "Update Profile"

    expect(page).to have_content("First Name can't be blank")
    expect(page).to have_content("Last Name can't be blank")
    expect(page).to have_content("Email Address can't be blank")
  end

  it "maintains the selected theme when form submission fails" do
    puts "[DEBUG] === STARTING TEST: maintains the selected theme when form submission fails ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Wait for form fields to be ready (longer waits in CI)
    expect(page).to have_field("First Name", wait: ci_wait_time)
    expect(page).to have_select("Theme", wait: ci_wait_time)

    fill_in "First Name", with: ""
    select "Sky", from: "Theme"
    click_button "Update Profile"

    expect(page).to have_content("First Name can't be blank")
    expect(page).to have_select("Theme", selected: "Sky")
  end
end
