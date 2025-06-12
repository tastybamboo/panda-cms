# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Menu, type: :model do
  fixtures :panda_cms_menus, :panda_cms_pages, :panda_cms_menu_items

  let(:static_menu) { panda_cms_menus(:main_menu) }
  let(:auto_menu) { panda_cms_menus(:auto_menu) }
  let(:homepage) { panda_cms_pages(:homepage) }

  describe "associations" do
    it "has many menu items ordered by lft" do
      expect(static_menu.menu_items.count).to eq(3)
      expect(static_menu.menu_items.first).to eq(panda_cms_menu_items(:home_link))
    end

    it "belongs to start_page optionally" do
      expect(auto_menu.start_page).to eq(homepage)
      expect(static_menu.start_page).to be_nil
    end
  end

  describe "validations" do
    it "validates presence of name" do
      menu = Panda::CMS::Menu.new(kind: "static")
      expect(menu).not_to be_valid
      expect(menu.errors[:name]).to include("can't be blank")
    end

    it "validates uniqueness of name" do
      menu = Panda::CMS::Menu.new(name: "Main Menu", kind: "static")
      expect(menu).not_to be_valid
      expect(menu.errors[:name]).to include("has already been taken")
    end

    it "validates presence of kind" do
      menu = Panda::CMS::Menu.new(name: "Test Menu", kind: nil)
      expect(menu).not_to be_valid
      expect(menu.errors[:kind]).to include("can't be blank")
    end

    it "validates inclusion of kind" do
      menu = Panda::CMS::Menu.new(name: "Test Menu", kind: "invalid")
      expect(menu).not_to be_valid
      expect(menu.errors[:kind]).to include("is not included in the list")
    end

    context "when kind is auto" do
      it "validates presence of start_page" do
        menu = Panda::CMS::Menu.new(name: "Test Auto Menu", kind: "auto")
        expect(menu).not_to be_valid
        expect(menu.errors[:start_page]).to include("can't be blank")
      end

      it "is valid with start_page present" do
        menu = Panda::CMS::Menu.new(name: "Test Auto Menu", kind: "auto", start_page: homepage)
        expect(menu).to be_valid
      end
    end

    context "when kind is static" do
      it "is valid without start_page" do
        menu = Panda::CMS::Menu.new(name: "Test Static Menu", kind: "static")
        expect(menu).to be_valid
      end
    end
  end

  describe "#generate_auto_menu_items" do
    let(:parent_page) { panda_cms_pages(:about_page) }
    let(:child_page) { panda_cms_pages(:services_page) }

    before do
      # Set up page hierarchy for testing
      child_page.update!(parent: parent_page)
      parent_page.update!(status: :active)
      child_page.update!(status: :active)
      auto_menu.update!(start_page: parent_page)
    end

    it "returns false when kind is not auto" do
      result = static_menu.generate_auto_menu_items
      expect(result).to be_falsey
    end

    it "creates menu items for start page and active children" do
      auto_menu.generate_auto_menu_items

      expect(auto_menu.menu_items.count).to be >= 2 # At least parent and child
    end

    it "creates root menu item for start page" do
      auto_menu.generate_auto_menu_items
      root_item = auto_menu.menu_items.roots.find_by(panda_cms_page_id: parent_page.id)

      expect(root_item).to be_present
      expect(root_item.text).to eq(parent_page.title)
      expect(root_item.page).to eq(parent_page)
    end

    it "creates nested menu items for child pages" do
      auto_menu.generate_auto_menu_items
      root_item = auto_menu.menu_items.roots.find_by(panda_cms_page_id: parent_page.id)
      child_item = auto_menu.menu_items.find_by(panda_cms_page_id: child_page.id)

      expect(child_item).to be_present
      expect(child_item.text).to eq(child_page.title)
      expect(child_item.parent).to eq(root_item)
    end

    it "only includes active pages" do
      child_page.update!(status: :draft)
      auto_menu.generate_auto_menu_items

      child_item = auto_menu.menu_items.find_by(panda_cms_page_id: child_page.id)
      expect(child_item).to be_nil
    end

    it "destroys existing menu items before creating new ones" do
      existing_item = auto_menu.menu_items.create!(text: "Existing", page: homepage)
      auto_menu.generate_auto_menu_items

      expect(Panda::CMS::MenuItem.exists?(existing_item.id)).to be_falsey
    end

    it "wraps operations in a transaction" do
      expect(auto_menu).to receive(:transaction).and_call_original
      auto_menu.generate_auto_menu_items
    end
  end

  describe "after_save callback" do
    it "generates auto menu items when kind is auto" do
      menu = Panda::CMS::Menu.create!(name: "Test Auto", kind: "auto", start_page: homepage)
      expect(menu.menu_items.count).to be > 0
    end

    it "does not generate menu items when kind is static" do
      menu = Panda::CMS::Menu.create!(name: "Test Static", kind: "static")
      expect(menu.menu_items.count).to eq(0)
    end
  end

  describe "fixture data integrity" do
    it "loads static menu correctly" do
      expect(static_menu.name).to eq("Main Menu")
      expect(static_menu.kind).to eq("static")
      expect(static_menu.start_page).to be_nil
    end

    it "loads auto menu correctly" do
      expect(auto_menu.name).to eq("Auto Menu")
      expect(auto_menu.kind).to eq("auto")
      expect(auto_menu.start_page).to eq(homepage)
    end

    it "has associated menu items" do
      expect(static_menu.menu_items.count).to eq(3)
      expect(panda_cms_menu_items(:home_link).menu).to eq(static_menu)
    end
  end
end
