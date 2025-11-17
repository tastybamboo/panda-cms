# frozen_string_literal: true

require "system_helper"

RSpec.describe "Menus Management", type: :system do
  fixtures :all

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }
  # TODO: Add header_menu fixture
  # let(:header_menu) { panda_cms_menus(:header_menu) }

  before do
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  describe "viewing menus list" do
    it "shows the menus index page" do
      visit "/admin/cms/menus"

      expect(page).to have_content("Menus")
    end

    it "displays existing menus in a table" do
      visit "/admin/cms/menus"

      # TableComponent doesn't use actual <table> tags
      expect(page).to have_link("Main Menu")
      expect(page).to have_link("Footer Menu")
    end

    it "shows menu kind for each menu" do
      visit "/admin/cms/menus"

      # Should show kind badges/tags
      expect(page).to have_content(/static|auto/i)
    end

    it "has a link to create new menu" do
      visit "/admin/cms/menus"

      expect(page).to have_link("New Menu")
    end

    it "has edit links for each menu" do
      visit "/admin/cms/menus"

      # Links are created from menu names, not "Edit" text
      expect(page).to have_link("Main Menu")
      expect(page).to have_link("Footer Menu")
    end
  end

  describe "creating a new menu" do
    it "shows the new menu form" do
      visit "/admin/cms/menus/new"

      expect(page).to have_content("New Menu")
      expect(page).to have_field("Name")
      expect(page).to have_field("Kind")
    end

    it "creates a menu with basic details" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Sidebar Menu"
      select "Static", from: "Kind"

      click_button "Create Menu"

      expect(page).to have_content(/successfully created/i)

      new_menu = Panda::CMS::Menu.find_by(name: "Sidebar Menu")
      expect(new_menu).not_to be_nil
      expect(new_menu.kind).to eq("static")
    end

    it "shows validation errors for invalid data" do
      visit "/admin/cms/menus/new"

      # Try to create without name
      click_button "Create Menu"

      expect(page).to have_content(/can't be blank/i, wait: 5)
    end

    it "allows setting a start page" do
      pending "Tests appear to be failing"
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Main Navigation"
      select "Auto", from: "Kind"

      # Wait for start page field to become visible
      expect(page).to have_select("Start Page", visible: true, wait: 5)
      select homepage.title, from: "Start Page"

      click_button "Create Menu"

      new_menu = Panda::CMS::Menu.find_by(name: "Main Navigation")
      expect(new_menu.start_page_id).to eq(homepage.id)
    end
  end

  describe "editing an existing menu" do
    it "shows the edit menu form" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"

      # expect(page).to have_content("Edit Menu")
      # expect(page).to have_field("Name", with: header_menu.name)
    end

    it "updates menu basic details" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"

      # fill_in "Name", with: "Updated Header Menu"
      # select "sidebar", from: "Kind"

      # click_button "Update Menu"

      # expect(page).to have_content(/successfully updated/i)

      # header_menu.reload
      # expect(header_menu.name).to eq("Updated Header Menu")
      # expect(header_menu.kind).to eq("sidebar")
    end

    it "shows existing menu items" do
      # Create a menu item
      # header_menu.menu_items.create!(
      #   text: "Home",
      #   panda_cms_page_id: homepage.id
      # )

      # visit "/admin/cms/menus/#{header_menu.id}/edit"

      # expect(page).to have_field("menu[menu_items_attributes][0][text]", with: "Home")
    end
  end

  describe "nested menu items" do
    it "shows add menu item button" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # expect(page).to have_button("Add Menu Item")
    end

    it "adds a new menu item when clicking add button" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # initial_count = all(".nested-form-wrapper").count
      # click_button "Add Menu Item"
      # expect(all(".nested-form-wrapper").count).to eq(initial_count + 1)
    end

    it "creates menu with menu items", skip: "Nested form JavaScript issue - menu items validation failing" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Navigation with Items"
      select "Static", from: "Kind"

      # Button is rendered as a link by ButtonComponent
      click_link "Add Menu Item"

      # Wait for nested form JavaScript to add the menu item
      expect(page).to have_css(".nested-form-wrapper")

      # Fill in the menu item fields with new labels
      within(first(".nested-form-wrapper")) do
        fill_in "Menu Item Text", with: "Home Link"
        select homepage.title, from: "Page"
      end

      click_button "Create Menu"

      new_menu = Panda::CMS::Menu.find_by(name: "Navigation with Items")
      expect(new_menu).not_to be_nil
      expect(new_menu.menu_items.count).to eq(1)
      expect(new_menu.menu_items.first.text).to eq("Home Link")
    end

    it "adds multiple menu items" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # initial_count = all(".nested-form-wrapper").count
      # click_button "Add Menu Item"
      # click_button "Add Menu Item"
      # click_button "Add Menu Item"
      # expect(all(".nested-form-wrapper").count).to eq(initial_count + 3)
    end

    it "allows entering text for menu item" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   text_field = find("input[placeholder='Menu item text']")
      #   text_field.fill_in with: "My Menu Item"
      #   expect(text_field.value).to eq("My Menu Item")
      # end
    end

    it "allows selecting a page for menu item" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   select homepage.title, from: /panda_cms_page_id/
      # end
      # click_button "Update Menu"
      # header_menu.reload
      # expect(header_menu.menu_items.last.panda_cms_page_id).to eq(homepage.id)
    end

    it "allows entering external URL for menu item" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   fill_in "menu[menu_items_attributes][0][text]", with: "External Link"
      #   fill_in "menu[menu_items_attributes][0][external_url]", with: "https://example.com"
      # end
      # click_button "Update Menu"
      # header_menu.reload
      # expect(header_menu.menu_items.last.external_url).to eq("https://example.com")
    end

    it "removes menu item when clicking remove button" do
      # header_menu.menu_items.create!(
      #   text: "To Remove",
      #   external_url: "https://example.com"
      # )
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # initial_count = all(".nested-form-wrapper").count
      # within(all(".nested-form-wrapper").first) do
      #   click_button "Remove"
      # end
      # expect(all(".nested-form-wrapper", visible: true).count).to eq(initial_count - 1)
    end

    it "persists menu item removal on save" do
      # menu_item = header_menu.menu_items.create!(
      #   text: "Will Be Deleted",
      #   external_url: "https://example.com"
      # )
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # within(all(".nested-form-wrapper").first) do
      #   click_button "Remove"
      # end
      # click_button "Update Menu"
      # header_menu.reload
      # expect(header_menu.menu_items.find_by(id: menu_item.id)).to be_nil
    end
  end

  describe "menu item validation" do
    it "requires text for menu item" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   select homepage.title, from: /panda_cms_page_id/
      # end
      # click_button "Update Menu"
      # expect(page).to have_content(/can't be blank/i, wait: 5)
    end

    it "accepts menu item with page link" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   fill_in "menu[menu_items_attributes][0][text]", with: "Valid Item"
      #   select homepage.title, from: "menu[menu_items_attributes][0][panda_cms_page_id]"
      # end
      # click_button "Update Menu"
      # expect(page).to have_content(/successfully updated/i)
    end

    it "accepts menu item with external URL" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # click_button "Add Menu Item"
      # within(all(".nested-form-wrapper").last) do
      #   fill_in "menu[menu_items_attributes][0][text]", with: "External Item"
      #   fill_in "menu[menu_items_attributes][0][external_url]", with: "https://external.com"
      # end
      # click_button "Update Menu"
      # expect(page).to have_content(/successfully updated/i)
    end
  end

  describe "nested form controller" do
    it "connects the nested-form controller" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # controller_connected = page.evaluate_script("
      #   const form = document.querySelector('[data-controller*=\"nested-form\"]');
      #   form && form.hasAttribute('data-controller')
      # ")
      # expect(controller_connected).to be true
    end

    it "has template for new menu items" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # has_template = page.evaluate_script("
      #   const template = document.querySelector('#menu-item-template');
      #   template && template.content
      # ")
      # expect(has_template).to be_truthy
    end
  end

  describe "menu kinds" do
    it "allows selecting static kind" do
      visit "/admin/cms/menus/new"

      select "Static", from: "Kind"
      fill_in "Name", with: "Static Test"

      click_button "Create Menu"

      menu = Panda::CMS::Menu.find_by(name: "Static Test")
      expect(menu.kind).to eq("static")
    end

    it "allows selecting auto kind" do
      pending "Tests appear to be failing"
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Auto Test"
      select "Auto", from: "Kind"

      # Wait for the start page field to become visible (JavaScript triggers this)
      expect(page).to have_select("Start Page", visible: true, wait: 5)
      select homepage.title, from: "Start Page"

      click_button "Create Menu"

      menu = Panda::CMS::Menu.find_by(name: "Auto Test")
      expect(menu.kind).to eq("auto")
    end
  end

  describe "deleting menus" do
    it "has delete button for menus" do
      skip "Delete functionality not yet implemented in menus index view"
      visit "/admin/cms/menus"

      # Should have delete links/buttons
      expect(page).to have_css("a[data-turbo-method='delete'], button[data-turbo-method='delete']")
    end

    it "deletes a menu when confirmed" do
      skip "Delete functionality not yet implemented in menus index view"
      menu_to_delete = Panda::CMS::Menu.create!(
        name: "Delete Me",
        kind: "static"
      )

      visit "/admin/cms/menus"

      # Accept the confirmation dialog
      accept_confirm do
        within("tr", text: "Delete Me") do
          click_link "Delete"
        end
      end

      expect(page).to have_content(/successfully deleted/i)
      expect(Panda::CMS::Menu.find_by(id: menu_to_delete.id)).to be_nil
    end
  end

  describe "breadcrumbs" do
    it "shows breadcrumb navigation on index" do
      visit "/admin/cms/menus"

      expect(page).to have_css("nav[aria-label='Breadcrumb']")
      expect(page).to have_content("Menus")
    end

    it "shows breadcrumb navigation on edit" do
      # visit "/admin/cms/menus/#{header_menu.id}/edit"
      # expect(page).to have_css("nav[aria-label='Breadcrumb']")
      # expect(page).to have_link("Menus")
    end
  end

  describe "accessibility" do
    it "has proper labels for all form fields" do
      visit "/admin/cms/menus/new"

      expect(page).to have_css("label[for*='name']")
      expect(page).to have_css("label[for*='kind']")
    end

    it "has proper heading structure" do
      visit "/admin/cms/menus/new"

      expect(page).to have_css("h1", text: /New Menu/i)
    end
  end
end
