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

    visit "/admin/my_profile/edit"
    expect(page).to have_content("My Profile", wait: 10)
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
    # Wait for form to be fully ready with all fields (longer waits in CI)
    expect(page).to have_field("First Name", wait: ci_wait_time)
    expect(page).to have_field("Last Name", wait: ci_wait_time)

    fill_in "First Name", with: "Updated"
    fill_in "Last Name", with: "Name"

    click_button "Update Profile"

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_field("First Name", with: "Updated")
    expect(page).to have_field("Last Name", with: "Name")
  end

  it "allows changing theme preference" do
    # Wait for JavaScript/Stimulus controllers to be ready
    expect(page).to have_css('[data-controller="theme-form"]', wait: ci_long_wait_time)

    # Wait for Theme select field to be ready (extra long waits for this problematic field)
    expect(page).to have_select("Theme", wait: ci_long_wait_time)

    select "Sky", from: "Theme"

    click_button "Update Profile"

    # Wait a moment for the form submission to process
    sleep(2)

    expect(page).to have_content("Your profile has been updated successfully")
    expect(page).to have_select("Theme", selected: "Sky")

    # Wait for theme to be applied
    using_wait_time(5) do
      expect(page.find("html")["data-theme"]).to eq("sky")
    end
  end

  it "validates required fields" do
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
