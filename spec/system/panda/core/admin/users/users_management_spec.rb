# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users Management", type: :system do
  let!(:admin_user) { create_admin_user }
  let!(:regular_user) { create_regular_user }

  before do
    driven_by :cuprite
    login_as_admin
  end

  describe "viewing users list" do
    it "shows the users index page" do
      visit panda_core.admin_users_path

      expect(page).to have_content("Users")
      expect(page).to have_content(admin_user.name)
      expect(page).to have_content(admin_user.email)
    end

    it "shows admin badge for admin users" do
      visit panda_core.admin_users_path

      within("[data-user-id='#{admin_user.id}']") do
        expect(page).to have_content("Admin")
      end
    end

    it "shows user badge for non-admin users" do
      visit panda_core.admin_users_path

      within("[data-user-id='#{regular_user.id}']") do
        expect(page).to have_content("User")
      end
    end

    it "has edit links for each user" do
      visit panda_core.admin_users_path

      expect(page).to have_link("Edit", href: panda_core.edit_admin_user_path(admin_user))
      expect(page).to have_link("Edit", href: panda_core.edit_admin_user_path(regular_user))
    end
  end

  describe "viewing user details" do
    it "shows user profile information" do
      visit panda_core.admin_user_path(regular_user)

      expect(page).to have_content(regular_user.name)
      expect(page).to have_content(regular_user.email)
      expect(page).to have_content("Standard User")
    end

    it "shows edit button" do
      visit panda_core.admin_user_path(regular_user)

      expect(page).to have_link("Edit", href: panda_core.edit_admin_user_path(regular_user))
    end
  end

  describe "editing a user" do
    it "shows the edit form with user details" do
      visit panda_core.edit_admin_user_path(regular_user)

      expect(page).to have_content("Edit User")
      expect(page).to have_field("Name", with: regular_user.name)
      expect(page).to have_field("Email", with: regular_user.email)
    end

    it "updates user name" do
      visit panda_core.edit_admin_user_path(regular_user)

      fill_in "Name", with: "New Name"
      click_button "Update User"

      expect(page).to have_content("User has been updated successfully")
      expect(regular_user.reload.name).to eq("New Name")
    end

    it "can grant admin status to a user" do
      visit panda_core.edit_admin_user_path(regular_user)

      check "Administrator"
      click_button "Update User"

      expect(page).to have_content("User has been updated successfully")
      expect(regular_user.reload.admin?).to be true
    end

    it "prevents changing own admin status" do
      visit panda_core.edit_admin_user_path(admin_user)

      expect(page).to have_field("Administrator", disabled: true)
      expect(page).to have_content("You cannot change your own admin status")
    end

    it "shows validation errors for invalid data" do
      visit panda_core.edit_admin_user_path(regular_user)

      fill_in "Email", with: ""
      click_button "Update User"

      expect(page).to have_content("Email can't be blank")
    end

    it "has cancel link back to users list" do
      visit panda_core.edit_admin_user_path(regular_user)

      expect(page).to have_link("Cancel", href: panda_core.admin_users_path)
    end
  end
end
