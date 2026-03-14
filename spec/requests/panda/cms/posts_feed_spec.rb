# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Posts Atom Feed", type: :request do
  fixtures :panda_cms_posts, :panda_cms_post_categories

  let(:admin) do
    Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |u|
      u.name = "Admin User"
      u.admin = true
    end
  end

  before do
    Panda::CMS::Post.find_each { |p| p.update!(user: admin, author: admin) }
  end

  describe "GET /blog.atom" do
    it "returns Atom XML with correct content type" do
      get "/blog.atom"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/atom\+xml})
    end

    it "returns valid Atom XML structure" do
      get "/blog.atom"
      doc = Nokogiri::XML(response.body)
      expect(doc.errors).to be_empty
      expect(doc.root.name).to eq("feed")
      expect(doc.root.namespace.href).to eq("http://www.w3.org/2005/Atom")
    end

    it "includes feed metadata" do
      get "/blog.atom"
      doc = Nokogiri::XML(response.body)
      ns = {"atom" => "http://www.w3.org/2005/Atom"}

      expect(doc.at_xpath("//atom:feed/atom:title", ns).text).to be_present
      expect(doc.at_xpath("//atom:feed/atom:id", ns).text).to include(".atom")
      expect(doc.at_xpath("//atom:feed/atom:updated", ns).text).to be_present
      expect(doc.at_xpath("//atom:feed/atom:link[@rel='self']", ns)["href"]).to include(".atom")
      expect(doc.at_xpath("//atom:feed/atom:link[@rel='alternate']", ns)["href"]).not_to include(".atom")
    end

    it "includes published posts as entries" do
      published = panda_cms_posts(:first_post)
      get "/blog.atom"
      doc = Nokogiri::XML(response.body)
      ns = {"atom" => "http://www.w3.org/2005/Atom"}

      entries = doc.xpath("//atom:entry", ns)
      expect(entries.length).to eq(1)

      entry = entries.first
      expect(entry.at_xpath("atom:title", ns).text).to eq(published.title)
      expect(entry.at_xpath("atom:published", ns).text).to be_present
      expect(entry.at_xpath("atom:updated", ns).text).to be_present
      expect(entry.at_xpath("atom:link", ns)["href"]).to include(published.slug)
    end

    it "excludes non-published posts" do
      hidden = panda_cms_posts(:second_post)
      get "/blog.atom"
      expect(response.body).not_to include(hidden.title)
    end

    it "includes author and category when present" do
      get "/blog.atom"
      doc = Nokogiri::XML(response.body)
      ns = {"atom" => "http://www.w3.org/2005/Atom"}

      entry = doc.at_xpath("//atom:entry", ns)
      expect(entry.at_xpath("atom:author/atom:name", ns).text).to eq("Admin User")
      expect(entry.at_xpath("atom:category", ns)["term"]).to be_present
    end

    context "HTTP caching" do
      it "returns 304 Not Modified for cached requests" do
        get "/blog.atom"
        expect(response).to have_http_status(:ok)

        etag = response.headers["ETag"]
        last_modified = response.headers["Last-Modified"]

        get "/blog.atom", headers: {"HTTP_IF_NONE_MATCH" => etag, "HTTP_IF_MODIFIED_SINCE" => last_modified}
        expect(response).to have_http_status(:not_modified)
      end

      it "sets Cache-Control to public" do
        get "/blog.atom"
        expect(response.headers["Cache-Control"]).to include("public")
      end
    end

    context "with no published posts" do
      before do
        Panda::CMS::Post.update_all(status: :hidden)
      end

      it "returns a valid empty feed" do
        get "/blog.atom"
        expect(response).to have_http_status(:ok)
        doc = Nokogiri::XML(response.body)
        expect(doc.errors).to be_empty
        expect(doc.xpath("//atom:entry", "atom" => "http://www.w3.org/2005/Atom")).to be_empty
      end
    end
  end
end
