# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts", type: :request do
  fixtures :panda_cms_posts, :panda_cms_post_categories

  let(:admin) do
    Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |u|
      u.name = "Admin User"
      u.admin = true
    end
  end

  before do
    Panda::CMS::Post.find_each { |p| p.update!(user: admin, author: admin) }

    # Configure post layouts for the dummy app (required for HTML rendering)
    Panda::CMS.config.posts = Panda::CMS.config.posts.merge(
      layouts: {show: "post", index: "page", by_month: "page"}
    )
  end

  describe "GET /blog/:year/:month/:slug (show)" do
    let(:post) { panda_cms_posts(:first_post) }
    let(:year) { Time.current.strftime("%Y") }
    let(:month) { Time.current.strftime("%m") }

    context "when post does not exist" do
      it "returns 404 for unknown slugs" do
        get "/blog/#{year}/#{month}/nonexistent-post"
        expect(response).to have_http_status(:not_found)
      end

      it "renders the engine 404 page" do
        get "/blog/#{year}/#{month}/nonexistent-post"
        expect(response.body).to include("Page Not Found")
      end
    end

    context "HTTP caching" do
      it "returns ETag and Last-Modified headers" do
        get "/blog/#{year}/#{month}/test-post-1"
        expect(response.headers["ETag"]).to be_present
        expect(response.headers["Last-Modified"]).to be_present
      end

      it "returns 304 Not Modified for cached requests" do
        get "/blog/#{year}/#{month}/test-post-1"
        etag = response.headers["ETag"]
        last_modified = response.headers["Last-Modified"]

        get "/blog/#{year}/#{month}/test-post-1",
          headers: {"HTTP_IF_NONE_MATCH" => etag, "HTTP_IF_MODIFIED_SINCE" => last_modified}
        expect(response).to have_http_status(:not_modified)
      end

      it "sets Cache-Control to public" do
        get "/blog/#{year}/#{month}/test-post-1"
        expect(response.headers["Cache-Control"]).to include("public")
      end
    end
  end

  describe "GET /blog/category/:category_slug (by_category)" do
    context "when category does not exist" do
      it "returns 404 for unknown categories" do
        get "/blog/category/nonexistent-category"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
