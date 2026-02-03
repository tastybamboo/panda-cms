# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin pages smoke tests", type: :system do
  # These tests ensure all admin pages can load without 500 errors
  # They're intentionally simple - just verify the page loads and doesn't crash

  let!(:admin_user) { create_admin_user }

  before do
    login_as_admin
  end

  describe "CMS Dashboard" do
    it "loads without errors" do
      visit "/admin/cms"
      expect(page).to have_content("Dashboard")
      expect(page.status_code).to eq(200)
    end
  end

  describe "Pages management" do
    it "loads pages index without errors" do
      visit "/admin/cms/pages"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    it "loads new page form without errors" do
      visit "/admin/cms/pages/new"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    context "with a test page", skip: "requires factory_bot setup" do
      let!(:test_page) { Panda::CMS::Page.create!(title: "Test Page", path: "/test") }

      it "loads page edit without errors" do
        visit "/admin/cms/pages/#{test_page.id}/edit"
        expect(page).to have_css("h1")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "Posts management" do
    it "loads posts index without errors" do
      visit "/admin/cms/posts"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    it "loads new post form without errors" do
      visit "/admin/cms/posts/new"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    context "with a test post", skip: "requires factory_bot setup" do
      let!(:test_post) { Panda::CMS::Post.create!(title: "Test Post") }

      it "loads post edit without errors" do
        visit "/admin/cms/posts/#{test_post.id}/edit"
        expect(page).to have_css("h1")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "Forms management" do
    it "loads forms index without errors" do
      visit "/admin/cms/forms"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    it "loads new form without errors" do
      visit "/admin/cms/forms/new"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    context "with a test form", skip: "requires factory_bot setup" do
      let!(:test_form) { Panda::CMS::Form.create!(name: "Test Form") }

      it "loads form edit without errors" do
        visit "/admin/cms/forms/#{test_form.id}/edit"
        expect(page).to have_css("h1")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "Menus management" do
    it "loads menus index without errors" do
      visit "/admin/cms/menus"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    it "loads new menu form without errors" do
      visit "/admin/cms/menus/new"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    context "with a test menu", skip: "requires factory_bot setup" do
      let!(:test_menu) { Panda::CMS::Menu.create!(name: "Test Menu") }

      it "loads menu edit without errors" do
        visit "/admin/cms/menus/#{test_menu.id}/edit"
        expect(page).to have_css("h1")
        expect(page.status_code).to eq(200)
      end
    end
  end

  describe "Files management" do
    it "loads files index without errors" do
      visit "/admin/cms/files"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end
  end

  describe "Settings" do
    it "loads settings page without errors" do
      visit "/admin/cms/settings"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end

    it "loads bulk editor without errors" do
      visit "/admin/cms/settings/bulk_editor"
      expect(page).to have_css("h1")
      expect(page.status_code).to eq(200)
    end
  end
end
