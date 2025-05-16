# panda-cms/spec/system/panda/cms/admin/my_profile_spec.rb
require "system_helper"

RSpec.describe "Admin profile management", type: :system do
  before(:each) do
    login_as_admin
    visit panda_cms.admin_edit_my_profile_path
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
      expect(page.find('html')['data-theme']).to eq("sky")
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
