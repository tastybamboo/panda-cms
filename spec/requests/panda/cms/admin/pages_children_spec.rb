# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Pages - Children", type: :request do
  fixtures :panda_cms_pages, :panda_cms_templates

  let(:admin_user) { create_admin_user }
  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  before do
    post "/admin/test_sessions", params: {user_id: admin_user.id}
  end

  describe "GET /admin/cms/pages/:id/children" do
    it "returns child page rows as HTML" do
      get "/admin/cms/pages/#{homepage.id}/children"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("About")
      expect(response.body).to include("Services")
    end

    it "does not include grandchild pages" do
      get "/admin/cms/pages/#{homepage.id}/children"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Team")
    end

    it "returns children of a nested page" do
      get "/admin/cms/pages/#{about_page.id}/children"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Team")
    end

    it "excludes archived pages by default" do
      about_page.update!(status: :archived)

      get "/admin/cms/pages/#{homepage.id}/children"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("About")
    end

    it "includes archived pages when show_archived is true" do
      about_page.update!(status: :archived)

      get "/admin/cms/pages/#{homepage.id}/children", params: {show_archived: "true"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("About")
    end

    it "returns empty for a leaf page" do
      team_page = panda_cms_pages(:about_team_page)

      get "/admin/cms/pages/#{team_page.id}/children"

      expect(response).to have_http_status(:ok)
      expect(response.body.strip).to be_empty
    end
  end
end
