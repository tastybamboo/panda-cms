# frozen_string_literal: true

# panda-cms/spec/system/panda/cms/admin/my_profile_spec.rb
require "system_helper"

RSpec.describe "Admin profile management", type: :system do
  fixtures :panda_cms_users
  before(:each) do
    login_as_admin

    puts "[DEBUG] After login_as_admin, about to visit profile path" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path before profile visit: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Session cookies before profile visit: #{page.driver.browser.cookies.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Debug route helper resolution
    profile_path = panda_cms.edit_admin_my_profile_path
    puts "[DEBUG] Route helper resolved to: #{profile_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # Try hardcoded path as alternative
    hardcoded_path = "/admin/my_profile/edit"
    puts "[DEBUG] Hardcoded path would be: #{hardcoded_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    visit profile_path

    puts "[DEBUG] After visiting profile path" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path after profile visit: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current URL after profile visit: #{page.current_url}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page content length after profile visit: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page title after profile visit: #{page.title}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

    # If route helper failed, try hardcoded path
    if page.current_path != "/admin/my_profile/edit" && page.html.length < 1000
      puts "[DEBUG] Route helper may have failed, trying hardcoded path" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
      visit hardcoded_path
      puts "[DEBUG] After hardcoded path - Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
      puts "[DEBUG] After hardcoded path - Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    end
  end

  it "displays the profile form with current user information" do
    expect(page).to have_content("My Profile")
    expect(page).to have_field("First Name")
    expect(page).to have_field("Last Name")
    expect(page).to have_field("Email Address")
    expect(page).to have_field("Theme")
    expect(page).to have_button("Update Profile")
  end

  it "allows updating profile information" do
    fill_in "First Name", with: "Updated"
    fill_in "Last Name", with: "Name"
    click_button "Update Profile"

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_field("First Name", with: "Updated")
    expect(page).to have_field("Last Name", with: "Name")
  end

  it "allows changing theme preference" do
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
    fill_in "First Name", with: ""
    fill_in "Last Name", with: ""
    fill_in "Email Address", with: ""
    click_button "Update Profile"

    expect(page).to have_content("First Name can't be blank")
    expect(page).to have_content("Last Name can't be blank")
    expect(page).to have_content("Email Address can't be blank")
  end

  it "maintains the selected theme when form submission fails" do
    fill_in "First Name", with: ""
    select "Sky", from: "Theme"
    click_button "Update Profile"

    expect(page).to have_content("First Name can't be blank")
    expect(page).to have_select("Theme", selected: "Sky")
  end
end
