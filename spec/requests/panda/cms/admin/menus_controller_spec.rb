# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Menus - Reordering", type: :request do
  fixtures :panda_cms_menus, :panda_cms_menu_items, :panda_cms_pages

  let(:admin_user) { create_admin_user }
  let(:main_menu) { panda_cms_menus(:main_menu) }
  let(:home_item) { panda_cms_menu_items(:home_link) }
  let(:about_item) { panda_cms_menu_items(:about_link) }
  let(:services_item) { panda_cms_menu_items(:services_link) }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "PATCH /admin/cms/menus/:id - reordering" do
    it "reorders existing menu items based on position params" do
      # Original order: Home(lft:1), About(lft:3), Services(lft:5)
      # Desired order: Services, Home, About
      patch "/admin/cms/menus/#{main_menu.id}", params: {
        menu: {
          name: main_menu.name,
          kind: main_menu.kind,
          menu_items_attributes: {
            "0" => {id: services_item.id, text: "Services", panda_cms_page_id: services_item.panda_cms_page_id, position: "0"},
            "1" => {id: home_item.id, text: "Home", panda_cms_page_id: home_item.panda_cms_page_id, position: "1"},
            "2" => {id: about_item.id, text: "About", panda_cms_page_id: about_item.panda_cms_page_id, position: "2"}
          }
        }
      }

      expect(response).to redirect_to("/admin/cms/menus")

      reordered = main_menu.menu_items.reload.order(:lft).pluck(:text)
      expect(reordered).to eq(["Services", "Home", "About"])
    end

    it "preserves order when positions match current order" do
      # Submit in the same order as current: Home, About, Services
      patch "/admin/cms/menus/#{main_menu.id}", params: {
        menu: {
          name: main_menu.name,
          kind: main_menu.kind,
          menu_items_attributes: {
            "0" => {id: home_item.id, text: "Home", panda_cms_page_id: home_item.panda_cms_page_id, position: "0"},
            "1" => {id: about_item.id, text: "About", panda_cms_page_id: about_item.panda_cms_page_id, position: "1"},
            "2" => {id: services_item.id, text: "Services", panda_cms_page_id: services_item.panda_cms_page_id, position: "2"}
          }
        }
      }

      expect(response).to redirect_to("/admin/cms/menus")

      reordered = main_menu.menu_items.reload.order(:lft).pluck(:text)
      expect(reordered).to eq(["Home", "About", "Services"])
    end

    it "handles reorder with a destroyed item" do
      # Destroy About, reorder: Services, Home
      patch "/admin/cms/menus/#{main_menu.id}", params: {
        menu: {
          name: main_menu.name,
          kind: main_menu.kind,
          menu_items_attributes: {
            "0" => {id: services_item.id, text: "Services", panda_cms_page_id: services_item.panda_cms_page_id, position: "0"},
            "1" => {id: home_item.id, text: "Home", panda_cms_page_id: home_item.panda_cms_page_id, position: "1"},
            "2" => {id: about_item.id, text: "About", panda_cms_page_id: about_item.panda_cms_page_id, _destroy: "1"}
          }
        }
      }

      expect(response).to redirect_to("/admin/cms/menus")

      reordered = main_menu.menu_items.reload.order(:lft).pluck(:text)
      expect(reordered).to eq(["Services", "Home"])
    end

    it "skips reorder when no position params are present" do
      patch "/admin/cms/menus/#{main_menu.id}", params: {
        menu: {
          name: "Renamed Menu",
          kind: main_menu.kind,
          menu_items_attributes: {
            "0" => {id: home_item.id, text: "Home", panda_cms_page_id: home_item.panda_cms_page_id},
            "1" => {id: about_item.id, text: "About", panda_cms_page_id: about_item.panda_cms_page_id}
          }
        }
      }

      expect(response).to redirect_to("/admin/cms/menus")

      reordered = main_menu.menu_items.reload.order(:lft).pluck(:text)
      expect(reordered).to eq(["Home", "About", "Services"])
    end
  end

  describe "POST /admin/cms/menus - create with reordering" do
    it "creates a menu and reorders items by position" do
      homepage = panda_cms_pages(:homepage)
      about_page = panda_cms_pages(:about_page)

      post "/admin/cms/menus", params: {
        menu: {
          name: "New Ordered Menu",
          kind: "static",
          menu_items_attributes: {
            "1000" => {text: "Second Link", panda_cms_page_id: about_page.id, position: "1"},
            "2000" => {text: "First Link", panda_cms_page_id: homepage.id, position: "0"}
          }
        }
      }

      expect(response).to redirect_to("/admin/cms/menus")

      new_menu = Panda::CMS::Menu.find_by(name: "New Ordered Menu")
      ordered = new_menu.menu_items.order(:lft).pluck(:text)
      expect(ordered).to eq(["First Link", "Second Link"])
    end
  end
end
