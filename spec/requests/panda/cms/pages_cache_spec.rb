# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CMS Page Cache Headers", type: :request do
  fixtures :panda_cms_templates, :panda_cms_pages

  before do
    # Ensure standard pages exist with templates
    setup_standard_pages if respond_to?(:setup_standard_pages)
  end

  describe "GET / (homepage)" do
    it "returns Cache-Control: public for anonymous requests" do
      get "/"
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("public")
      expect(response.headers["Cache-Control"]).not_to include("private")
    end

    it "includes ETag header for conditional caching" do
      get "/"
      expect(response.headers["ETag"]).to be_present
    end

    it "returns 304 when ETag matches" do
      get "/"
      etag = response.headers["ETag"]

      get "/", headers: {"HTTP_IF_NONE_MATCH" => etag}
      expect(response).to have_http_status(:not_modified)
    end
  end

  describe "GET /about (content page)" do
    it "returns Cache-Control: public for anonymous requests" do
      get "/about"
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("public")
      expect(response.headers["Cache-Control"]).not_to include("private")
    end
  end
end
