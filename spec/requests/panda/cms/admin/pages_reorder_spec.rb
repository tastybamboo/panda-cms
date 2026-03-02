# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Pages - Reorder", type: :request do
  fixtures :panda_cms_menus, :panda_cms_menu_items, :panda_cms_pages, :panda_cms_templates

  let(:admin_user) { create_admin_user }
  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }
  let(:services_page) { panda_cms_pages(:services_page) }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "POST /admin/cms/pages/:id/reorder" do
    it "moves a page before a sibling" do
      # Services(lft:6) should move before About(lft:2)
      post "/admin/cms/pages/#{services_page.id}/reorder", params: {
        target_id: about_page.id,
        position: "before"
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["success"]).to be true

      # Reload and check order
      about_page.reload
      services_page.reload
      expect(services_page.lft).to be < about_page.lft
    end

    it "moves a page after a sibling" do
      # About(lft:2) should move after Services(lft:6)
      post "/admin/cms/pages/#{about_page.id}/reorder", params: {
        target_id: services_page.id,
        position: "after"
      }, as: :json

      expect(response).to have_http_status(:ok)

      about_page.reload
      services_page.reload
      expect(about_page.lft).to be > services_page.lft
    end

    it "rejects reordering non-siblings" do
      team_page = panda_cms_pages(:about_team_page) # child of about, not sibling of services

      post "/admin/cms/pages/#{team_page.id}/reorder", params: {
        target_id: services_page.id,
        position: "before"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Can only reorder siblings")
    end

    it "rejects invalid position values" do
      post "/admin/cms/pages/#{about_page.id}/reorder", params: {
        target_id: services_page.id,
        position: "invalid"
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Invalid position")
    end

    it "regenerates auto menus after reordering" do
      auto_menu = panda_cms_menus(:auto_menu)
      expect(auto_menu.start_page).to eq(homepage)

      post "/admin/cms/pages/#{services_page.id}/reorder", params: {
        target_id: about_page.id,
        position: "before"
      }, as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
