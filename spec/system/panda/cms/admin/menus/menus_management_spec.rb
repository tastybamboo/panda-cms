# frozen_string_literal: true

require "system_helper"

RSpec.describe "Menus Management", type: :system do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }
  let(:header_menu) { panda_cms_menus(:header_menu) }

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  describe "viewing menus list" do
    it "shows the menus index page" do
      visit "/admin/cms/menus"

      expect(page).to have_content("Menus", wait: 10)
    end

    it "displays existing menus in a table" do
      visit "/admin/cms/menus"

      expect(page).to have_css("table", wait: 10)
      expect(page).to have_content(header_menu.name)
    end

    it "shows menu kind for each menu" do
      visit "/admin/cms/menus"

      # Should show kind badges/tags
      expect(page).to have_content(/header|footer|sidebar/i, wait: 10)
    end

    it "has a link to create new menu" do
      visit "/admin/cms/menus"

      expect(page).to have_link("New Menu", wait: 10)
    end

    it "has edit links for each menu" do
      visit "/admin/cms/menus"

      expect(page).to have_link("Edit", wait: 10)
    end
  end

  describe "creating a new menu" do
    it "shows the new menu form" do
      visit "/admin/cms/menus/new"

      expect(page).to have_content("New Menu", wait: 10)
      expect(page).to have_field("Name")
      expect(page).to have_field("Kind")
    end

    it "creates a menu with basic details" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Footer Menu"
      select "footer", from: "Kind"

      click_button "Create Menu"

      expect(page).to have_content(/successfully created/i, wait: 10)

      new_menu = Panda::CMS::Menu.find_by(name: "Footer Menu")
      expect(new_menu).not_to be_nil
      expect(new_menu.kind).to eq("footer")
    end

    it "shows validation errors for invalid data" do
      visit "/admin/cms/menus/new"

      # Try to create without name
      click_button "Create Menu"

      expect(page).to have_content(/can't be blank/i, wait: 5)
    end

    it "allows setting a start page" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Main Navigation"
      select "header", from: "Kind"
      select homepage.title, from: "Start page"

      click_button "Create Menu"

      new_menu = Panda::CMS::Menu.find_by(name: "Main Navigation")
      expect(new_menu.start_page_id).to eq(homepage.id)
    end
  end

  describe "editing an existing menu" do
    it "shows the edit menu form" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_content("Edit Menu", wait: 10)
      expect(page).to have_field("Name", with: header_menu.name)
    end

    it "updates menu basic details" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      fill_in "Name", with: "Updated Header Menu"
      select "sidebar", from: "Kind"

      click_button "Update Menu"

      expect(page).to have_content(/successfully updated/i, wait: 10)

      header_menu.reload
      expect(header_menu.name).to eq("Updated Header Menu")
      expect(header_menu.kind).to eq("sidebar")
    end

    it "shows existing menu items" do
      # Create a menu item
      header_menu.menu_items.create!(
        text: "Home",
        panda_cms_page_id: homepage.id
      )

      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_field("menu[menu_items_attributes][0][text]", with: "Home", wait: 10)
    end
  end

  describe "nested menu items" do
    it "shows add menu item button" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_button("Add Menu Item", wait: 10)
    end

    it "adds a new menu item when clicking add button" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      initial_count = all(".nested-form-wrapper").count

      click_button "Add Menu Item"

      # Should add one more menu item field
      expect(all(".nested-form-wrapper").count).to eq(initial_count + 1)
    end

    it "creates menu with menu items" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Navigation with Items"
      select "header", from: "Kind"

      click_button "Add Menu Item"

      # Fill in the menu item fields (needs JavaScript to work properly)
      within(all(".nested-form-wrapper").last) do
        fill_in "menu[menu_items_attributes][0][text]", with: "Home Link"
        select homepage.title, from: "menu[menu_items_attributes][0][panda_cms_page_id]"
      end

      click_button "Create Menu"

      new_menu = Panda::CMS::Menu.find_by(name: "Navigation with Items")
      expect(new_menu).not_to be_nil
      expect(new_menu.menu_items.count).to eq(1)
      expect(new_menu.menu_items.first.text).to eq("Home Link")
    end

    it "adds multiple menu items" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      initial_count = all(".nested-form-wrapper").count

      click_button "Add Menu Item"
      click_button "Add Menu Item"
      click_button "Add Menu Item"

      expect(all(".nested-form-wrapper").count).to eq(initial_count + 3)
    end

    it "allows entering text for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        text_field = find("input[placeholder='Menu item text']")
        text_field.fill_in with: "My Menu Item"
        expect(text_field.value).to eq("My Menu Item")
      end
    end

    it "allows selecting a page for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        select homepage.title, from: /panda_cms_page_id/
      end

      click_button "Update Menu"

      header_menu.reload
      expect(header_menu.menu_items.last.panda_cms_page_id).to eq(homepage.id)
    end

    it "allows entering external URL for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        fill_in "menu[menu_items_attributes][0][text]", with: "External Link"
        fill_in "menu[menu_items_attributes][0][external_url]", with: "https://example.com"
      end

      click_button "Update Menu"

      header_menu.reload
      expect(header_menu.menu_items.last.external_url).to eq("https://example.com")
    end

    it "removes menu item when clicking remove button" do
      # Create a menu item first
      header_menu.menu_items.create!(
        text: "To Remove",
        external_url: "https://example.com"
      )

      visit "/admin/cms/menus/#{header_menu.id}/edit"

      initial_count = all(".nested-form-wrapper").count

      # Click remove button
      within(all(".nested-form-wrapper").first) do
        click_button "Remove"
      end

      # Should have one less item visible
      expect(all(".nested-form-wrapper", visible: true).count).to eq(initial_count - 1)
    end

    it "persists menu item removal on save" do
      menu_item = header_menu.menu_items.create!(
        text: "Will Be Deleted",
        external_url: "https://example.com"
      )

      visit "/admin/cms/menus/#{header_menu.id}/edit"

      within(all(".nested-form-wrapper").first) do
        click_button "Remove"
      end

      click_button "Update Menu"

      header_menu.reload
      expect(header_menu.menu_items.find_by(id: menu_item.id)).to be_nil
    end
  end

  describe "menu item validation" do
    it "requires text for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      # Leave text empty but fill other fields
      within(all(".nested-form-wrapper").last) do
        select homepage.title, from: /panda_cms_page_id/
      end

      click_button "Update Menu"

      expect(page).to have_content(/can't be blank/i, wait: 5)
    end

    it "accepts menu item with page link" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        fill_in "menu[menu_items_attributes][0][text]", with: "Valid Item"
        select homepage.title, from: "menu[menu_items_attributes][0][panda_cms_page_id]"
      end

      click_button "Update Menu"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end

    it "accepts menu item with external URL" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_button "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        fill_in "menu[menu_items_attributes][0][text]", with: "External Item"
        fill_in "menu[menu_items_attributes][0][external_url]", with: "https://external.com"
      end

      click_button "Update Menu"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end
  end

  describe "nested form controller" do
    it "connects the nested-form controller" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      controller_connected = page.evaluate_script("
        const form = document.querySelector('[data-controller*=\"nested-form\"]');
        form && form.hasAttribute('data-controller')
      ")

      expect(controller_connected).to be true
    end

    it "has template for new menu items" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      has_template = page.evaluate_script("
        const template = document.querySelector('#menu-item-template');
        template && template.content
      ")

      expect(has_template).to be_truthy
    end
  end

  describe "menu kinds" do
    it "allows selecting header kind" do
      visit "/admin/cms/menus/new"

      select "header", from: "Kind"
      fill_in "Name", with: "Header Test"

      click_button "Create Menu"

      menu = Panda::CMS::Menu.find_by(name: "Header Test")
      expect(menu.kind).to eq("header")
    end

    it "allows selecting footer kind" do
      visit "/admin/cms/menus/new"

      select "footer", from: "Kind"
      fill_in "Name", with: "Footer Test"

      click_button "Create Menu"

      menu = Panda::CMS::Menu.find_by(name: "Footer Test")
      expect(menu.kind).to eq("footer")
    end

    it "allows selecting sidebar kind" do
      visit "/admin/cms/menus/new"

      select "sidebar", from: "Kind"
      fill_in "Name", with: "Sidebar Test"

      click_button "Create Menu"

      menu = Panda::CMS::Menu.find_by(name: "Sidebar Test")
      expect(menu.kind).to eq("sidebar")
    end
  end

  describe "deleting menus" do
    it "has delete button for menus" do
      visit "/admin/cms/menus"

      # Should have delete links/buttons
      expect(page).to have_css("a[data-turbo-method='delete'], button[data-turbo-method='delete']", wait: 10)
    end

    it "deletes a menu when confirmed" do
      menu_to_delete = Panda::CMS::Menu.create!(
        name: "Delete Me",
        kind: "footer"
      )

      visit "/admin/cms/menus"

      # Accept the confirmation dialog
      accept_confirm do
        within("tr", text: "Delete Me") do
          click_link "Delete"
        end
      end

      expect(page).to have_content(/successfully deleted/i, wait: 10)
      expect(Panda::CMS::Menu.find_by(id: menu_to_delete.id)).to be_nil
    end
  end

  describe "breadcrumbs" do
    it "shows breadcrumb navigation on index" do
      visit "/admin/cms/menus"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_content("Menus")
    end

    it "shows breadcrumb navigation on edit" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_css("nav[aria-label='Breadcrumb']", wait: 10)
      expect(page).to have_link("Menus")
    end
  end

  describe "accessibility" do
    it "has proper labels for all form fields" do
      visit "/admin/cms/menus/new"

      expect(page).to have_css("label[for*='name']", wait: 10)
      expect(page).to have_css("label[for*='kind']")
    end

    it "has proper heading structure" do
      visit "/admin/cms/menus/new"

      expect(page).to have_css("h1", text: /New Menu/i, wait: 10)
    end
  end
end
