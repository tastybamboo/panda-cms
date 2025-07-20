# frozen_string_literal: true

# panda-cms/spec/system/panda/cms/admin/my_profile_spec.rb
require "system_helper"

RSpec.describe "Admin profile management", type: :system do
  fixtures :panda_cms_users

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

    # Debug available form fields before attempting to fill them
    if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
      puts "[DEBUG] Available form fields:"
      page.all('input, select, textarea').each do |field|
        puts "[DEBUG]   Field: name='#{field[:name]}', id='#{field[:id]}', type='#{field[:type]}'"
      end
      puts "[DEBUG] Looking for 'First Name' field..."
    end

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
    select "Sky", from: "Theme"
    click_button "Update Profile"

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_select("Theme", selected: "Sky")

    # Wait for theme to be applied
    using_wait_time(5) do
      expect(page.find("html")["data-theme"]).to eq("sky")
    end
  end

  it "validates required fields" do
    puts "[DEBUG] === STARTING TEST: validates required fields ===" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
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
    fill_in "First Name", with: ""
    select "Sky", from: "Theme"
    click_button "Update Profile"

    expect(page).to have_content("First Name can't be blank")
    expect(page).to have_select("Theme", selected: "Sky")
  end
end
