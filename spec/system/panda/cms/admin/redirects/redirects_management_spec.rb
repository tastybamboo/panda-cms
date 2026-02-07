# frozen_string_literal: true

require "system_helper"

RSpec.describe "Redirects Management", type: :system do
  let!(:admin_user) { create_admin_user }

  let!(:redirect_301) do
    Panda::CMS::Redirect.create!(
      origin_path: "/old-page",
      destination_path: "/new-page",
      status_code: 301,
      visits: 5
    )
  end

  let!(:redirect_302) do
    Panda::CMS::Redirect.create!(
      origin_path: "/temp-page",
      destination_path: "/current-page",
      status_code: 302,
      visits: 0
    )
  end

  before do
    login_as_admin
  end

  describe "viewing redirects list" do
    it "shows the redirects index page" do
      visit "/admin/cms/redirects"

      expect(page).to have_content("Redirects", wait: 10)
    end

    it "displays existing redirects" do
      visit "/admin/cms/redirects"

      expect(page).to have_content("/old-page", wait: 10)
      expect(page).to have_content("/new-page")
      expect(page).to have_content("/temp-page")
      expect(page).to have_content("/current-page")
    end

    it "shows status code tags" do
      visit "/admin/cms/redirects"

      expect(page).to have_content("Permanent", wait: 10)
      expect(page).to have_content("Temporary")
    end

    it "shows visit counts" do
      visit "/admin/cms/redirects"

      expect(page).to have_content("Visits", wait: 10)
      # The redirect_301 fixture has 5 visits
      within(".table-row-group") do
        expect(page).to have_content("5")
      end
    end

    it "has a button to create a new redirect" do
      visit "/admin/cms/redirects"

      expect(page).to have_css("a[href*='/redirects/new']", wait: 10)
    end

    it "has links to edit each redirect" do
      visit "/admin/cms/redirects"

      expect(page).to have_link("/old-page", wait: 10)
    end
  end

  describe "creating a new redirect" do
    it "shows the new redirect form" do
      visit "/admin/cms/redirects/new"

      expect(page).to have_content("New Redirect", wait: 10)
      expect(page).to have_field("Origin path")
      expect(page).to have_field("Destination path")
    end

    it "creates a redirect with valid data" do
      visit "/admin/cms/redirects/new"

      fill_in "Origin path", with: "/blog/old-post"
      fill_in "Destination path", with: "/blog/new-post"
      select "301 — Permanent", from: "Status Code"

      click_button "Create Redirect"

      expect(page).to have_content(/successfully created/i, wait: 10)

      new_redirect = Panda::CMS::Redirect.find_by(origin_path: "/blog/old-post")
      expect(new_redirect).not_to be_nil
      expect(new_redirect.destination_path).to eq("/blog/new-post")
      expect(new_redirect.status_code).to eq(301)
    end

    it "shows validation errors when origin path is missing" do
      visit "/admin/cms/redirects/new"

      expect(page).to have_css("form", wait: 5)

      fill_in "Destination path", with: "/new-path"
      click_button "Create Redirect"

      expect(page).to have_content("can't be blank", wait: 5)
    end

    it "shows validation errors when paths don't start with /" do
      visit "/admin/cms/redirects/new"

      expect(page).to have_css("form", wait: 5)

      fill_in "Origin path", with: "no-slash"
      fill_in "Destination path", with: "/valid-path"
      click_button "Create Redirect"

      expect(page).to have_content("must start with a forward slash", wait: 5)
    end
  end

  describe "editing a redirect" do
    it "shows the edit form with existing values" do
      visit "/admin/cms/redirects/#{redirect_301.id}/edit"

      expect(page).to have_field("Origin path", with: "/old-page", wait: 10)
      expect(page).to have_field("Destination path", with: "/new-page")
    end

    it "updates a redirect" do
      visit "/admin/cms/redirects/#{redirect_301.id}/edit"

      fill_in "Origin path", with: "/updated-origin"
      fill_in "Destination path", with: "/updated-destination"

      click_button "Save Redirect"

      expect(page).to have_content(/successfully updated/i, wait: 10)

      redirect_301.reload
      expect(redirect_301.origin_path).to eq("/updated-origin")
      expect(redirect_301.destination_path).to eq("/updated-destination")
    end

    it "shows statistics panel" do
      visit "/admin/cms/redirects/#{redirect_301.id}/edit"

      expect(page).to have_content("Statistics", wait: 10)
      expect(page).to have_content("Total Visits")
      expect(page).to have_content("5")
    end

    it "has a delete button" do
      visit "/admin/cms/redirects/#{redirect_301.id}/edit"

      expect(page).to have_css("a[data-turbo-method='delete']", wait: 10)
    end
  end

  describe "deleting a redirect" do
    it "has delete links on the index page" do
      visit "/admin/cms/redirects"

      expect(page).to have_css("a[data-turbo-method='delete']", wait: 10)
    end

    it "can delete a redirect" do
      redirect_to_delete = Panda::CMS::Redirect.create!(
        origin_path: "/delete-me",
        destination_path: "/somewhere",
        status_code: 301,
        visits: 0
      )

      visit "/admin/cms/redirects"

      expect(page).to have_content("/delete-me", wait: 10)

      expect {
        redirect_to_delete.destroy
      }.to change(Panda::CMS::Redirect, :count).by(-1)
    end
  end

  describe "breadcrumbs" do
    it "shows breadcrumb navigation on index" do
      visit "/admin/cms/redirects"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_content("Redirects")
    end

    it "shows breadcrumb navigation on new" do
      visit "/admin/cms/redirects/new"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_link("Redirects")
      expect(page).to have_content("New Redirect")
    end

    it "shows breadcrumb navigation on edit" do
      visit "/admin/cms/redirects/#{redirect_301.id}/edit"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_link("Redirects")
    end
  end
end
