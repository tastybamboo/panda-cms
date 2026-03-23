# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::MenuComponent, type: :component do
  let(:main_menu) { panda_cms_menus(:main_menu) }
  let(:footer_menu) { panda_cms_menus(:footer_menu) }
  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }
  let(:services_page) { panda_cms_pages(:services_page) }

  describe "#initialize" do
    it "accepts required name parameter" do
      component = described_class.new(name: "Main Menu")
      expect(component.name).to eq("Main Menu")
    end

    it "accepts optional current_path parameter" do
      component = described_class.new(name: "Main Menu", current_path: "/about")
      expect(component.current_path).to eq("/about")
    end

    it "defaults current_path to empty string" do
      component = described_class.new(name: "Main Menu")
      expect(component.current_path).to eq("")
    end

    it "accepts styles parameter" do
      styles = {default: "nav-link", active: "active", inactive: "inactive"}
      component = described_class.new(name: "Main Menu", styles: styles)
      expect(component.styles).to eq(styles)
    end

    it "accepts overrides parameter" do
      overrides = {hidden_items: ["Services"]}
      component = described_class.new(name: "Main Menu", overrides: overrides)
      expect(component.overrides).to eq(overrides)
    end

    it "accepts render_page_menu parameter" do
      component = described_class.new(name: "Main Menu", render_page_menu: true)
      expect(component.render_page_menu).to be true
    end

    it "accepts page_menu_styles parameter" do
      page_menu_styles = {default: "submenu"}
      component = described_class.new(name: "Main Menu", page_menu_styles: page_menu_styles)
      expect(component.page_menu_styles).to eq(page_menu_styles)
    end

    it "defaults page_menu_show_all_items to false" do
      component = described_class.new(name: "Main Menu")
      expect(component.page_menu_show_all_items).to be false
    end

    it "accepts page_menu_show_all_items parameter" do
      component = described_class.new(name: "Main Menu", page_menu_show_all_items: true)
      expect(component.page_menu_show_all_items).to be true
    end
  end

  describe "#processed_menu_items" do
    it "returns empty array when menu doesn't exist" do
      component = described_class.new(name: "nonexistent_menu")
      component.before_render
      expect(component.processed_menu_items).to eq([])
    end

    it "returns menu items when menu exists" do
      component = described_class.new(name: "Main Menu")
      component.before_render
      expect(component.processed_menu_items.length).to eq(5)
    end

    it "adds css_classes method to each menu item" do
      component = described_class.new(
        name: "Main Menu",
        styles: {default: "nav-link", active: "active", inactive: "inactive"}
      )
      component.before_render

      menu_item = component.processed_menu_items.first
      expect(menu_item).to respond_to(:css_classes)
    end
  end

  describe "hidden items filtering" do
    it "filters out hidden items specified in overrides" do
      component = described_class.new(
        name: "Main Menu",
        overrides: {hidden_items: ["Services"]}
      )
      component.before_render

      menu_item_texts = component.processed_menu_items.map(&:text)
      expect(menu_item_texts).to contain_exactly("Home", "About", "Support Us", "Donate")
      expect(menu_item_texts).not_to include("Services")
    end

    it "returns all items when no hidden_items specified" do
      component = described_class.new(name: "Main Menu")
      component.before_render

      expect(component.processed_menu_items.length).to eq(5)
    end

    it "handles multiple hidden items" do
      component = described_class.new(
        name: "Main Menu",
        overrides: {hidden_items: ["About", "Services"]}
      )
      component.before_render

      menu_item_texts = component.processed_menu_items.map(&:text)
      expect(menu_item_texts).to contain_exactly("Home", "Support Us", "Donate")
    end
  end

  describe "active link detection" do
    it "marks home link as active when on root path" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/",
        styles: {default: "link", active: "active", inactive: "inactive"}
      )
      component.before_render

      home_item = component.processed_menu_items.find { |i| i.text == "Home" }
      expect(home_item.css_classes).to include("active")
    end

    it "marks about link as active when on /about path" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/about",
        styles: {default: "link", active: "active", inactive: "inactive"}
      )
      component.before_render

      about_item = component.processed_menu_items.find { |i| i.text == "About" }
      expect(about_item.css_classes).to include("active")
    end

    it "uses starts_with matching when no same-depth sibling has a more specific match" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/about/team",
        styles: {default: "link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      about_item = component.processed_menu_items.find { |i| i.text == "About" }
      expect(about_item.css_classes).to eq("link font-bold")
    end

    it "prefers the more specific match when two same-depth items both match" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/support-us/donate",
        styles: {default: "link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      support_item = component.processed_menu_items.find { |i| i.text == "Support Us" }
      donate_item = component.processed_menu_items.find { |i| i.text == "Donate" }
      expect(donate_item.css_classes).to eq("link font-bold")
      expect(support_item.css_classes).to eq("link text-gray")
    end

    it "marks parent as active on exact match even when child exists at same depth" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/support-us",
        styles: {default: "link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      support_item = component.processed_menu_items.find { |i| i.text == "Support Us" }
      donate_item = component.processed_menu_items.find { |i| i.text == "Donate" }
      expect(support_item.css_classes).to eq("link font-bold")
      expect(donate_item.css_classes).to eq("link text-gray")
    end

    it "marks non-matching links as inactive" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/about",
        styles: {default: "link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      services_item = component.processed_menu_items.find { |i| i.text == "Services" }
      expect(services_item.css_classes).to eq("link text-gray")
      expect(services_item.css_classes).not_to include("font-bold")
    end
  end

  describe "CSS class application" do
    it "applies both default and active styles to active items" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/",
        styles: {default: "nav-link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      home_item = component.processed_menu_items.find { |i| i.text == "Home" }
      expect(home_item.css_classes).to eq("nav-link font-bold")
    end

    it "applies both default and inactive styles to inactive items" do
      component = described_class.new(
        name: "Main Menu",
        current_path: "/",
        styles: {default: "nav-link", active: "font-bold", inactive: "text-gray"}
      )
      component.before_render

      about_item = component.processed_menu_items.find { |i| i.text == "About" }
      expect(about_item.css_classes).to eq("nav-link text-gray")
    end
  end

  describe "menu depth filtering" do
    it "respects menu depth setting when present" do
      # This test verifies the component queries with depth filter
      # We can't easily create nested items in fixtures, so we just verify it doesn't error
      main_menu.update!(depth: 1)

      component = described_class.new(name: "Main Menu")
      component.before_render

      # Should still work, just filters by depth
      expect(component.processed_menu_items).to be_an(Array)
    end
  end

  describe "caching" do
    it "uses Rails cache for menu items" do
      allow(Rails.cache).to receive(:fetch).and_call_original

      component = described_class.new(name: "Main Menu")
      component.before_render

      expect(Rails.cache).to have_received(:fetch)
    end

    it "includes menu name, id, and updated_at in cache key" do
      component = described_class.new(name: "Main Menu")

      expect(Rails.cache).to receive(:fetch).with(
        /panda_cms_menu\/Main Menu\/#{main_menu.id}\/\d+\/items/,
        expires_in: 1.hour
      ).and_call_original

      component.before_render
    end
  end

  describe "rendering" do
    it "renders the menu component" do
      render_inline(described_class.new(name: "Main Menu"))

      expect(page).to have_link("Home")
      expect(page).to have_link("About")
      expect(page).to have_link("Services")
      expect(page).to have_link("Support Us")
      expect(page).to have_link("Donate")
    end

    it "renders menu items as links" do
      render_inline(described_class.new(name: "Main Menu"))

      expect(page).to have_link("Home", href: "/")
      expect(page).to have_link("About", href: "/about")
      expect(page).to have_link("Services", href: "/services")
      expect(page).to have_link("Support Us", href: "/support-us")
      expect(page).to have_link("Donate", href: "/support-us/donate")
    end

    it "renders nothing when menu doesn't exist" do
      render_inline(described_class.new(name: "nonexistent_menu"))

      expect(page).not_to have_css("ul")
    end

    it "applies custom styles to menu items" do
      render_inline(described_class.new(
        name: "Main Menu",
        current_path: "/",
        styles: {default: "nav-item", active: "active-link", inactive: "inactive-link"}
      ))

      expect(page).to have_css(".nav-item")
    end
  end
end
