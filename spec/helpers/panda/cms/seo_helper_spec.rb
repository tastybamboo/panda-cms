# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::SeoHelper, type: :helper do
  let(:test_template) do
    allow(File).to receive(:file?).and_return(true)
    template = Panda::CMS::Template.find_or_create_by!(
      name: "SEO Helper Test",
      file_path: "layouts/seo_helper_test"
    )
    RSpec::Mocks.space.proxy_for(File).reset
    template
  end

  let(:root_page) do
    page = Panda::CMS::Page.new(
      path: "/",
      title: "Root",
      template: test_template,
      status: "active"
    )
    page.save(validate: false)
    page
  end

  let(:test_page) do
    allow_any_instance_of(Panda::CMS::Page).to receive(:create_redirect_if_path_changed).and_return(true)
    Panda::CMS::Page.create!(
      title: "Test Page",
      path: "/test",
      parent: root_page,
      template: test_template,
      seo_title: "Custom SEO Title",
      seo_description: "Custom SEO description for testing",
      seo_keywords: "test, keywords",
      og_title: "Custom OG Title",
      og_description: "Custom OG description",
      og_type: "article"
    )
  end

  let(:admin_user) { create_admin_user }
  let(:test_post) do
    Panda::CMS::Post.create!(
      title: "Test Post",
      slug: "/test-post",
      user: admin_user,
      author: admin_user,
      seo_title: "Post SEO Title",
      seo_description: "Post SEO description",
      og_title: "Post OG Title"
    )
  end

  before do
    # Mock request object for URL generation
    allow(helper).to receive(:request).and_return(
      double(
        protocol: "https://",
        host_with_port: "example.com"
      )
    )
  end

  describe "#render_seo_meta_tags" do
    it "returns empty string for nil resource" do
      expect(helper.render_seo_meta_tags(nil)).to eq("")
    end

    context "with a page" do
      it "renders meta description" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('name="description"')
        expect(result).to include("Custom SEO description for testing")
      end

      it "renders meta keywords" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('name="keywords"')
        expect(result).to include("test, keywords")
      end

      it "renders robots meta tag" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('name="robots"')
        expect(result).to include("index, follow")
      end

      it "renders canonical link" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('rel="canonical"')
        expect(result).to include("https://example.com/test")
      end

      it "renders Open Graph tags" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('property="og:title"')
        expect(result).to include("Custom OG Title")
        expect(result).to include('property="og:description"')
        expect(result).to include("Custom OG description")
        expect(result).to include('property="og:type"')
        expect(result).to include("article")
        expect(result).to include('property="og:url"')
        expect(result).to include("https://example.com/test")
      end

      it "renders Twitter Card tags" do
        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('name="twitter:card"')
        expect(result).to include("summary_large_image")
        expect(result).to include('name="twitter:title"')
        expect(result).to include("Custom OG Title")
        expect(result).to include('name="twitter:description"')
      end

      it "doesn't render optional fields when blank" do
        allow_any_instance_of(Panda::CMS::Page).to receive(:create_redirect_if_path_changed).and_return(true)
        minimal_page = Panda::CMS::Page.create!(
          title: "Minimal",
          path: "/minimal",
          parent: root_page,
          template: test_template
        )

        result = helper.render_seo_meta_tags(minimal_page)
        expect(result).not_to include('name="keywords"')
      end
    end

    context "with a post" do
      it "renders post meta tags" do
        result = helper.render_seo_meta_tags(test_post)
        expect(result).to include("Post SEO description")
        expect(result).to include("Post OG Title") # OG title is rendered, not SEO title
        expect(result).to include('property="og:type"')
        expect(result).to include("article")
      end
    end

    context "with og_image attached" do
      it "renders og:image tags with dimensions" do
        # Mock the og_image attachment
        allow(test_page).to receive_message_chain(:og_image, :attached?).and_return(true)
        allow(test_page).to receive_message_chain(:og_image, :variant).and_return(
          double(url: "https://example.com/image.jpg")
        )
        allow(helper).to receive(:url_for).and_return("https://example.com/image.jpg")

        result = helper.render_seo_meta_tags(test_page)
        expect(result).to include('property="og:image"')
        expect(result).to include("https://example.com/image.jpg")
        expect(result).to include('property="og:image:width"')
        expect(result).to include("1200")
        expect(result).to include('property="og:image:height"')
        expect(result).to include("630")
        expect(result).to include('name="twitter:image"')
      end
    end
  end

  describe "#seo_title" do
    it "returns just the page title by default" do
      result = helper.seo_title(test_page)
      expect(result).to eq("Custom SEO Title")
    end

    it "includes site name when provided" do
      result = helper.seo_title(test_page, site_name: "My Site")
      expect(result).to eq("Custom SEO Title · My Site")
    end

    it "uses custom separator" do
      result = helper.seo_title(test_page, site_name: "My Site", separator: " | ")
      expect(result).to eq("Custom SEO Title | My Site")
    end
  end

  describe "#canonical_url_for (private)" do
    it "uses canonical_url if it's a full URL" do
      test_page.canonical_url = "https://custom.com/page"
      result = helper.send(:canonical_url_for, test_page)
      expect(result).to eq("https://custom.com/page")
    end

    it "constructs full URL from path" do
      result = helper.send(:canonical_url_for, test_page)
      expect(result).to eq("https://example.com/test")
    end
  end
end
