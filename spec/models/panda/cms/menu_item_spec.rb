# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::MenuItem, type: :model do
  fixtures :panda_cms_menus, :panda_cms_menu_items, :panda_cms_pages

  let(:main_menu) { panda_cms_menus(:main_menu) }
  let(:footer_menu) { panda_cms_menus(:footer_menu) }
  let(:home_link) { panda_cms_menu_items(:home_link) }
  let(:about_link) { panda_cms_menu_items(:about_link) }
  let(:external_link) { panda_cms_menu_items(:external_link) }
  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  describe "associations" do
    it "belongs to menu" do
      expect(home_link.menu).to eq(main_menu)
    end

    it "belongs to page optionally" do
      expect(home_link.page).to eq(homepage)
      expect(external_link.page).to be_nil
    end
  end

  describe "validations" do
    it "validates presence of text" do
      menu_item = Panda::CMS::MenuItem.new(menu: main_menu, page: homepage)
      expect(menu_item).not_to be_valid
      expect(menu_item.errors[:text]).to include("can't be blank")
    end

    it "validates uniqueness of text scoped to menu" do
      menu_item = Panda::CMS::MenuItem.new(
        text: "Home",
        menu: main_menu,
        page: about_page
      )
      expect(menu_item).not_to be_valid
      expect(menu_item.errors[:text]).to include("has already been taken")
    end

    it "allows same text in different menus" do
      menu_item = Panda::CMS::MenuItem.new(
        text: "Home",
        menu: footer_menu,
        page: about_page
      )
      expect(menu_item).to be_valid
    end

    context "when page is present" do
      it "is valid without external_url" do
        menu_item = Panda::CMS::MenuItem.new(
          text: "Test Link",
          menu: main_menu,
          page: homepage,
          external_url: nil
        )
        expect(menu_item).to be_valid
      end

      it "is invalid with both page and external_url" do
        menu_item = Panda::CMS::MenuItem.new(
          text: "Test Link",
          menu: main_menu,
          page: homepage,
          external_url: "https://example.com"
        )
        expect(menu_item).not_to be_valid
        expect(menu_item.errors[:page]).to include("must be a valid page or external link, both are set")
        expect(menu_item.errors[:external_url]).to include("must be a valid page or external link, both are set")
      end
    end

    context "when external_url is present" do
      it "is valid without page" do
        menu_item = Panda::CMS::MenuItem.new(
          text: "External",
          menu: main_menu,
          page: nil,
          external_url: "https://example.com"
        )
        expect(menu_item).to be_valid
      end

      it "is invalid with both page and external_url" do
        menu_item = Panda::CMS::MenuItem.new(
          text: "Test Link",
          menu: main_menu,
          page: homepage,
          external_url: "https://example.com"
        )
        expect(menu_item).not_to be_valid
        expect(menu_item.errors[:page]).to include("must be a valid page or external link, both are set")
        expect(menu_item.errors[:external_url]).to include("must be a valid page or external link, both are set")
      end
    end

    context "when neither page nor external_url is present" do
      it "is invalid" do
        menu_item = Panda::CMS::MenuItem.new(
          text: "Invalid Link",
          menu: main_menu,
          page: nil,
          external_url: nil
        )
        expect(menu_item).not_to be_valid
        expect(menu_item.errors[:page]).to include("must be a valid page or external link, neither are set")
        expect(menu_item.errors[:external_url]).to include("must be a valid page or external link, neither are set")
      end
    end
  end

  describe "nested set behavior" do
    let(:parent_item) { home_link }
    let!(:child_item) do
      main_menu.menu_items.create!(
        text: "Child Item",
        page: about_page,
        parent: parent_item
      )
    end

    it "acts as nested set" do
      expect(parent_item.children).to include(child_item)
      expect(child_item.parent).to eq(parent_item)
    end

    it "maintains left and right values" do
      parent_item.reload
      child_item.reload

      expect(parent_item.lft).to be < parent_item.rgt
      expect(child_item.lft).to be > parent_item.lft
      expect(child_item.rgt).to be < parent_item.rgt
    end

    it "updates children_count" do
      parent_item.reload
      expect(parent_item.children_count).to eq(1)
    end

    it "scopes nested set to menu" do
      other_menu_item = footer_menu.menu_items.create!(
        text: "Other Menu Item",
        external_url: "https://other.com"
      )

      # Items in different menus can have same lft/rgt values
      # The new item should be positioned after the existing external_link
      expect(other_menu_item.lft).to eq(3)
      expect(other_menu_item.rgt).to eq(4)
    end
  end

  describe "#resolved_link" do
    context "when menu item has a page" do
      it "returns the page path" do
        expect(home_link.resolved_link).to eq(homepage.path)
      end
    end

    context "when menu item has an external URL" do
      it "returns the external URL" do
        expect(external_link.resolved_link).to eq("https://example.com")
      end
    end

    context "when menu item has neither page nor external URL" do
      let(:empty_item) do
        Panda::CMS::MenuItem.new(
          text: "Empty",
          menu: main_menu,
          page: nil,
          external_url: nil
        )
      end

      it "returns empty string" do
        expect(empty_item.resolved_link).to eq("")
      end
    end
  end

  describe "table configuration" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("panda_cms_menu_items")
    end

    it "uses lft column for implicit ordering" do
      expect(described_class.implicit_order_column).to eq("lft")
    end
  end

  describe "touching menu" do
    it "touches the menu when updated" do
      original_time = main_menu.updated_at
      sleep(0.01) # Ensure time difference

      home_link.update!(text: "Updated Home")

      expect(main_menu.reload.updated_at).to be > original_time
    end
  end

  describe "fixture data integrity" do
    it "loads home link correctly" do
      expect(home_link.text).to eq("Home")
      expect(home_link.menu).to eq(main_menu)
      expect(home_link.page).to eq(homepage)
      expect(home_link.external_url).to be_nil
    end

    it "loads about link correctly" do
      expect(about_link.text).to eq("About")
      expect(about_link.menu).to eq(main_menu)
      expect(about_link.page).to eq(about_page)
    end

    it "loads external link correctly" do
      expect(external_link.text).to eq("External Link")
      expect(external_link.menu).to eq(footer_menu)
      expect(external_link.external_url).to eq("https://example.com")
      expect(external_link.page).to be_nil
    end

    it "has correct nested set values" do
      expect(home_link.lft).to eq(1)
      expect(home_link.rgt).to eq(2)
      expect(home_link.depth).to eq(0)
      expect(home_link.children_count).to eq(0)
    end
  end
end
