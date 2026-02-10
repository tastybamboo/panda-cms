# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitemap", type: :request do
  fixtures :panda_cms_templates, :panda_cms_pages

  let(:admin) do
    Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |u|
      u.name = "Admin User"
      u.admin = true
    end
  end

  describe "GET /sitemap.xml" do
    it "returns XML with correct content type" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/xml})
    end

    it "returns valid sitemap XML structure" do
      get "/sitemap.xml"
      doc = Nokogiri::XML(response.body)
      expect(doc.errors).to be_empty
      expect(doc.root.name).to eq("urlset")
      expect(doc.root.namespace.href).to eq("http://www.sitemaps.org/schemas/sitemap/0.9")
    end

    it "includes active visible pages" do
      get "/sitemap.xml"
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

      expect(urls).to include(a_string_ending_with("/"))
      expect(urls).to include(a_string_ending_with("/about"))
      expect(urls).to include(a_string_ending_with("/about/team"))
      expect(urls).to include(a_string_ending_with("/services"))
    end

    it "includes lastmod for pages" do
      get "/sitemap.xml"
      doc = Nokogiri::XML(response.body)
      lastmods = doc.xpath("//xmlns:lastmod", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      expect(lastmods).not_to be_empty
      lastmods.each do |node|
        expect { Time.iso8601(node.text) }.not_to raise_error
      end
    end

    context "with draft pages" do
      before do
        Panda::CMS::Page.create!(
          title: "Draft Page",
          path: "/draft-page",
          status: :draft,
          template: panda_cms_templates(:page_template),
          parent: panda_cms_pages(:homepage)
        )
      end

      it "excludes draft pages" do
        get "/sitemap.xml"
        expect(response.body).not_to include("/draft-page")
      end
    end

    context "with archived pages" do
      before do
        Panda::CMS::Page.create!(
          title: "Archived Page",
          path: "/archived-page",
          status: :archived,
          template: panda_cms_templates(:page_template),
          parent: panda_cms_pages(:homepage)
        )
      end

      it "excludes archived pages" do
        get "/sitemap.xml"
        expect(response.body).not_to include("/archived-page")
      end
    end

    context "with noindex pages" do
      before do
        panda_cms_pages(:services_page).update!(seo_index_mode: :invisible)
      end

      it "excludes pages with seo_index_mode invisible" do
        get "/sitemap.xml"
        doc = Nokogiri::XML(response.body)
        urls = doc.xpath("//xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)
        expect(urls).not_to include(a_string_ending_with("/services"))
      end
    end

    context "with hidden_type pages" do
      before do
        Panda::CMS::Page.create!(
          title: "Hidden Type Page",
          path: "/hidden-type-page",
          status: :active,
          page_type: :hidden_type,
          template: panda_cms_templates(:page_template),
          parent: panda_cms_pages(:homepage)
        )
      end

      it "excludes hidden_type pages" do
        get "/sitemap.xml"
        expect(response.body).not_to include("/hidden-type-page")
      end
    end

    context "with system pages" do
      before do
        Panda::CMS::Page.create!(
          title: "System Page",
          path: "/system-page",
          status: :active,
          page_type: :system,
          template: panda_cms_templates(:page_template),
          parent: panda_cms_pages(:homepage)
        )
      end

      it "excludes system pages" do
        get "/sitemap.xml"
        expect(response.body).not_to include("/system-page")
      end
    end

    context "with canonical URLs" do
      before do
        panda_cms_pages(:about_page).update!(canonical_url: "https://example.com/about-us")
      end

      it "uses canonical_url when present" do
        get "/sitemap.xml"
        expect(response.body).to include("https://example.com/about-us")
      end
    end

    context "with posts enabled" do
      fixtures :panda_cms_posts

      before do
        Panda::CMS::Post.find_each { |p| p.update!(user: admin, author: admin) }
      end

      it "includes active visible posts" do
        get "/sitemap.xml"
        doc = Nokogiri::XML(response.body)
        urls = doc.xpath("//xmlns:loc", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9").map(&:text)

        active_post = panda_cms_posts(:first_post)
        expect(urls).to include(a_string_including("blog#{active_post.slug}"))
      end

      it "excludes draft posts" do
        get "/sitemap.xml"
        draft_post = panda_cms_posts(:second_post)
        expect(response.body).not_to include(draft_post.slug)
      end

      context "with post canonical URL" do
        before do
          panda_cms_posts(:first_post).update!(canonical_url: "https://example.com/my-post")
        end

        it "uses canonical_url for posts when present" do
          get "/sitemap.xml"
          expect(response.body).to include("https://example.com/my-post")
        end
      end
    end

    context "with posts disabled" do
      around do |example|
        original = Panda::CMS.config.posts[:enabled]
        Panda::CMS.config.posts[:enabled] = false
        example.run
        Panda::CMS.config.posts[:enabled] = original
      end

      it "does not include any post URLs" do
        get "/sitemap.xml"
        expect(response.body).not_to include("blog/")
      end
    end

    context "HTTP caching" do
      it "returns 304 Not Modified for cached requests" do
        get "/sitemap.xml"
        expect(response).to have_http_status(:ok)

        last_modified = response.headers["Last-Modified"]
        expect(last_modified).to be_present

        get "/sitemap.xml", headers: {"HTTP_IF_MODIFIED_SINCE" => last_modified}
        expect(response).to have_http_status(:not_modified)
      end

      it "sets Cache-Control to public" do
        get "/sitemap.xml"
        expect(response.headers["Cache-Control"]).to include("public")
      end
    end
  end
end
