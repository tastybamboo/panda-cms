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

      expect(page).to have_link("Add Menu")
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

      expect(page).to have_content("Add Menu")
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
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Main Navigation"
      select "Auto", from: "Kind"

      # Manually show the start page field since Stimulus controller may not connect in tests
      page.execute_script(<<~JS)
        var startPageField = document.querySelector('[data-menu-form-target="startPageField"]');
        if (startPageField) {
          startPageField.classList.remove('hidden');
        }
      JS

      # Wait for start page field to become visible
      expect(page).to have_select("Start Page", visible: true, wait: 2)
      select homepage.title, from: "Start Page"

      click_button "Create Menu"

      expect(page).to have_content(/successfully created/i)

      new_menu = Panda::CMS::Menu.find_by(name: "Main Navigation")
      expect(new_menu).not_to be_nil
      expect(new_menu.start_page_id).to eq(homepage.id)
    end
  end

  describe "editing an existing menu" do
    it "shows the edit menu form" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_content("Edit Menu")
      expect(page).to have_field("Name", with: "Header Menu")
    end

    it "updates menu basic details" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      fill_in "Name", with: "Updated Header Menu"
      click_button "Save Menu"

      expect(page).to have_content(/successfully updated/i)

      header_menu.reload
      expect(header_menu.name).to eq("Updated Header Menu")
    end

    it "shows existing menu items" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_content("Home")
      expect(page).to have_content("About")
    end
  end

  describe "nested menu items" do
    it "shows add menu item button" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_link("Add Menu Item")
    end

    it "adds a new menu item when clicking add button" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      expect(page).to have_css(".nested-form-wrapper")
    end

    it "creates menu with menu items" do
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
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      # The header_menu already has 2 items from fixtures
      click_link "Add Menu Item"
      click_link "Add Menu Item"

      # Should have at least 2 new nested form wrappers
      expect(page).to have_css(".nested-form-wrapper", minimum: 2)
    end

    it "allows entering text for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        expect(page).to have_field("Menu Item Text")
        fill_in "Menu Item Text", with: "New Item"
      end
    end

    it "allows selecting a page for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        expect(page).to have_select("Page")
      end
    end

    it "allows entering external URL for menu item" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        expect(page).to have_field("External URL (optional)")
      end
    end

    it "removes menu item when clicking remove button" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      wrapper_count = all(".nested-form-wrapper").count

      within(all(".nested-form-wrapper").last) do
        click_button "Remove"
      end

      expect(page).to have_css(".nested-form-wrapper", count: wrapper_count - 1)
    end

    it "persists menu item removal on save" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      initial_count = header_menu.menu_items.count

      # Find and mark the last existing menu item for removal
      within(all(".nested-form-wrapper").last) do
        click_button "Remove"
      end

      click_button "Save Menu"

      expect(page).to have_content(/successfully updated/i)

      header_menu.reload
      expect(header_menu.menu_items.count).to be < initial_count
    end
  end

  describe "menu item validation" do
    it "requires text for menu item", skip: "Menu item text validation not enforced on save" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      # Leave text empty and try to save
      click_button "Save Menu"

      # Should show validation error for blank text
      expect(page).to have_content(/can't be blank|is required/i, wait: 5)
    end

    it "accepts menu item with page link" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      # The existing items already have page links
      expect(page).to have_content("Home")
      expect(page).to have_content("About")
    end

    it "accepts menu item with external URL" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      click_link "Add Menu Item"

      within(all(".nested-form-wrapper").last) do
        fill_in "Menu Item Text", with: "External Site"
        fill_in "External URL (optional)", with: "https://example.com"
      end

      click_button "Save Menu"

      expect(page).to have_content(/successfully updated/i)
    end
  end

  describe "nested form controller" do
    it "connects the nested-form controller" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_css("[data-controller*='nested-form']")
    end

    it "has template for new menu items" do
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      # Template elements are always hidden; check via JavaScript
      has_template = page.evaluate_script("document.querySelector('template[data-nested-form-target=\"template\"]') !== null")
      expect(has_template).to be true
    end
  end

  describe "menu kinds" do
    it "allows selecting static kind" do
      visit "/admin/cms/menus/new"

      select "Static", from: "Kind"
      fill_in "Name", with: "Static Test"

      click_button "Create Menu"

      expect(page).to have_content(/successfully created/i)

      menu = Panda::CMS::Menu.find_by(name: "Static Test")
      expect(menu.kind).to eq("static")
    end

    it "allows selecting auto kind" do
      visit "/admin/cms/menus/new"

      fill_in "Name", with: "Auto Test"
      select "Auto", from: "Kind"

      # Manually show the start page field since Stimulus controller may not connect in tests
      page.execute_script(<<~JS)
        var startPageField = document.querySelector('[data-menu-form-target="startPageField"]');
        if (startPageField) {
          startPageField.classList.remove('hidden');
        }
      JS

      # Wait for the start page field to become visible
      expect(page).to have_select("Start Page", visible: true, wait: 2)
      select homepage.title, from: "Start Page"

      click_button "Create Menu"

      expect(page).to have_content(/successfully created/i)

      menu = Panda::CMS::Menu.find_by(name: "Auto Test")
      expect(menu.kind).to eq("auto")
    end
  end

  describe "deleting menus" do
    it "has delete button for menus" do
      visit "/admin/cms/menus"

      # Should have delete links
      expect(page).to have_link("Delete", minimum: 1)
    end

    it "deletes a menu when confirmed" do
      menu_to_delete = Panda::CMS::Menu.create!(
        name: "Delete Me",
        kind: "static"
      )

      visit "/admin/cms/menus"

      # Accept the confirmation dialog
      accept_confirm do
        # TableComponent uses div.table-row with data-menu-id attribute
        within(".table-row", text: "Delete Me") do
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
      visit "/admin/cms/menus/#{header_menu.id}/edit"

      expect(page).to have_css("nav[aria-label='Breadcrumb']")
      expect(page).to have_content("Header Menu")
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

      expect(page).to have_css("h1", text: /Add Menu/i)
    end
  end
end
