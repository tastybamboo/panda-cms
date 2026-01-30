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

    context "ordering validation" do
      it "defaults to 'default'" do
        menu = Panda::CMS::Menu.new(name: "Test Menu", kind: "static")
        expect(menu.ordering).to eq("default")
      end

      it "is valid with 'default' ordering" do
        menu = Panda::CMS::Menu.new(name: "Test Menu", kind: "static", ordering: "default")
        expect(menu).to be_valid
      end

      it "is valid with 'alphabetical' ordering" do
        menu = Panda::CMS::Menu.new(name: "Test Menu", kind: "static", ordering: "alphabetical")
        expect(menu).to be_valid
      end

      it "is invalid with unknown ordering" do
        menu = Panda::CMS::Menu.new(name: "Test Menu", kind: "static", ordering: "invalid")
        expect(menu).not_to be_valid
        expect(menu.errors[:ordering]).to include("is not included in the list")
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

    context "with alphabetical ordering" do
      let(:template) { panda_cms_pages(:homepage).template }
      let(:test_parent) do
        Panda::CMS::Page.create!(
          title: "Test Parent",
          path: "/test-parent",
          parent: homepage,
          template: template,
          status: :active
        )
      end
      let(:alphabetical_menu) do
        Panda::CMS::Menu.create!(
          name: "Alphabetical Test Menu",
          kind: "auto",
          ordering: "alphabetical",
          start_page: test_parent
        )
      end

      before do
        # Create test pages as children in non-alphabetical order
        Panda::CMS::Page.create!(title: "Zebra Page", path: "/test-parent/zebra", parent: test_parent, template: template, status: :active)
        Panda::CMS::Page.create!(title: "Alpha Page", path: "/test-parent/alpha", parent: test_parent, template: template, status: :active)
        Panda::CMS::Page.create!(title: "Middle Page", path: "/test-parent/middle", parent: test_parent, template: template, status: :active)
      end

      it "orders menu items alphabetically by title" do
        alphabetical_menu.generate_auto_menu_items
        root_item = alphabetical_menu.menu_items.roots.find_by(panda_cms_page_id: test_parent.id)
        child_items = root_item.children.order(:lft)

        titles = child_items.map(&:text)
        expect(titles).to eq(["Alpha Page", "Middle Page", "Zebra Page"])
      end

      it "includes 'Alpha Page' before 'Zebra Page'" do
        alphabetical_menu.generate_auto_menu_items
        alpha_item = alphabetical_menu.menu_items.find_by(text: "Alpha Page")
        zebra_item = alphabetical_menu.menu_items.find_by(text: "Zebra Page")

        expect(alpha_item).to be_present
        expect(zebra_item).to be_present
        expect(alpha_item.lft).to be < zebra_item.lft
      end
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

  describe "nested attributes" do
    it "allows removing menu items via _destroy" do
      menu = static_menu
      item = menu.menu_items.first

      expect {
        menu.update!(menu_items_attributes: [{id: item.id, _destroy: "1"}])
      }.to change { menu.menu_items.count }.by(-1)
    end

    it "allows removing multiple menu items at once" do
      menu = static_menu
      items = menu.menu_items.to_a

      attrs = items.map { |item| {id: item.id, _destroy: "1"} }

      expect {
        menu.update!(menu_items_attributes: attrs)
      }.to change { menu.menu_items.count }.by(-items.size)
    end

    it "allows removing some items while keeping others" do
      menu = static_menu
      keep_item = panda_cms_menu_items(:home_link)
      remove_item = panda_cms_menu_items(:about_link)

      expect {
        menu.update!(menu_items_attributes: [
          {id: keep_item.id, text: keep_item.text},
          {id: remove_item.id, _destroy: "1"}
        ])
      }.to change { menu.menu_items.count }.by(-1)

      expect(menu.menu_items.reload).to include(keep_item)
      expect(menu.menu_items.reload).not_to include(remove_item)
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
