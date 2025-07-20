# frozen_string_literal: true

# panda-cms/spec/system/panda/cms/admin/my_profile_spec.rb
require "system_helper"

RSpec.describe "Admin profile management", type: :system do
  fixtures :panda_cms_users

  before(:each) do
    login_as_admin
    visit panda_cms.edit_admin_my_profile_path
  end

  it "displays the profile form with current user information" do
    puts "[DEBUG] Starting test assertions - checking page state" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Page content length: #{page.html.length}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

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
    puts "[DEBUG] Starting profile update test" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]
    puts "[DEBUG] Current path before form interaction: #{page.current_path}" if ENV["GITHUB_ACTIONS"] || ENV["DEBUG"]

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
