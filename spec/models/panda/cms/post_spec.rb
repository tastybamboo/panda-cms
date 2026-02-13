# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Post, type: :model do
  describe "editor content", :editorjs do
    let(:admin_user) { create_admin_user }
    let(:post) do
      Panda::CMS::Post.create!(
        title: "Test Post",
        slug: "/test-post",
        user: admin_user,
        author: admin_user,
        status: "published"
      )
    end

    it "stores and caches EditorJS content" do
      editor_content = {
        "source" => "editorJS",
        "time" => Time.current.to_i,
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {
              "text" => "Test content"
            }
          }
        ]
      }

      post.content = editor_content
      post.save!
      post.reload

      expect(post.content).to eq(editor_content)
      expect(post.cached_content).to include("<p>Test content</p>")
    end
  end

  describe ".editor_search" do
    let(:admin_user) { create_admin_user }

    let!(:active_post) do
      Panda::CMS::Post.create!(
        title: "Active Post",
        slug: "/active-post",
        user: admin_user,
        author: admin_user,
        status: "published"
      )
    end

    let!(:draft_post) do
      Panda::CMS::Post.create!(
        title: "Draft Post",
        slug: "/draft-post",
        user: admin_user,
        author: admin_user,
        status: "hidden"
      )
    end

    let!(:another_active_post) do
      Panda::CMS::Post.create!(
        title: "Another Active Post",
        slug: "/another-active-post",
        user: admin_user,
        author: admin_user,
        status: "published"
      )
    end

    it "returns only active records" do
      results = Panda::CMS::Post.editor_search("post")
      names = results.map { |r| r[:name] }
      expect(names).to include("Active Post")
      expect(names).not_to include("Draft Post")
    end

    it "matches by title" do
      results = Panda::CMS::Post.editor_search("Another Active")
      expect(results.length).to eq(1)
      expect(results.first[:name]).to eq("Another Active Post")
    end

    it "matches by slug" do
      results = Panda::CMS::Post.editor_search("active-post")
      expect(results.map { |r| r[:name] }).to include("Active Post")
    end

    it "respects limit" do
      results = Panda::CMS::Post.editor_search("post", limit: 1)
      expect(results.length).to eq(1)
    end

    it "returns correct hash structure" do
      results = Panda::CMS::Post.editor_search("Active Post")
      result = results.find { |r| r[:name] == "Active Post" }
      expect(result).to include(:href, :name, :description)
      expect(result[:href]).to match(/blog/)
      expect(result[:name]).to eq("Active Post")
      expect(result[:description]).to eq("Post")
    end
  end

  describe "SEO functionality" do
    let(:admin_user) { create_admin_user }
    let(:post) do
      Panda::CMS::Post.create!(
        title: "Test Post",
        slug: "/test-post",
        user: admin_user,
        author: admin_user,
        status: "published"
      )
    end

    describe "SEO validations" do
      it { should validate_length_of(:seo_title).is_at_most(70) }
      it { should validate_length_of(:seo_description).is_at_most(160) }
      it { should validate_length_of(:og_title).is_at_most(60) }
      it { should validate_length_of(:og_description).is_at_most(200) }

      it "validates canonical URL format" do
        post.canonical_url = "not-a-url"
        expect(post).not_to be_valid
        expect(post.errors[:canonical_url]).to be_present
      end

      it "allows valid canonical URL" do
        post.canonical_url = "https://example.com/post"
        expect(post).to be_valid
      end
    end

    describe "SEO enums" do
      it "has seo_index_mode enum" do
        expect(post.seo_visible?).to be true
        post.seo_invisible!
        expect(post.seo_invisible?).to be true
      end

      it "has og_type enum with article default" do
        expect(post.og_article?).to be true
        post.og_website!
        expect(post.og_website?).to be true
      end
    end

    describe "#effective_seo_title" do
      it "returns seo_title when present" do
        post.seo_title = "Custom SEO Title"
        expect(post.effective_seo_title).to eq("Custom SEO Title")
      end

      it "falls back to title when seo_title is blank" do
        expect(post.effective_seo_title).to eq("Test Post")
      end
    end

    describe "#effective_seo_description" do
      it "returns seo_description when present" do
        post.seo_description = "Custom description"
        expect(post.effective_seo_description).to eq("Custom description")
      end

      it "falls back to excerpt when seo_description is blank" do
        post.content = {
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {"text" => "This is the post content that will be excerpted"}
            }
          ]
        }
        expect(post.effective_seo_description).to include("This is the post content")
      end
    end

    describe "#effective_og_title" do
      it "returns og_title when present" do
        post.og_title = "Custom OG Title"
        expect(post.effective_og_title).to eq("Custom OG Title")
      end

      it "falls back to effective_seo_title" do
        post.seo_title = "SEO Title"
        expect(post.effective_og_title).to eq("SEO Title")
      end
    end

    describe "#effective_og_description" do
      it "returns og_description when present" do
        post.og_description = "OG description"
        expect(post.effective_og_description).to eq("OG description")
      end

      it "falls back to effective_seo_description" do
        post.seo_description = "SEO description"
        expect(post.effective_og_description).to eq("SEO description")
      end
    end

    describe "#effective_canonical_url" do
      it "returns canonical_url when present" do
        post.canonical_url = "https://example.com/canonical"
        expect(post.effective_canonical_url).to eq("https://example.com/canonical")
      end

      it "falls back to post slug" do
        # Post slugs are formatted with date prefix (YYYY/MM/slug)
        expect(post.effective_canonical_url).to match(%r{\A/\d{4}/\d{2}/test-post\z})
      end
    end

    describe "#robots_meta_content" do
      it "returns 'index, follow' when visible" do
        post.seo_index_mode = "visible"
        expect(post.robots_meta_content).to eq("index, follow")
      end

      it "returns 'noindex, nofollow' when invisible" do
        post.seo_index_mode = "invisible"
        expect(post.robots_meta_content).to eq("noindex, nofollow")
      end
    end

    describe "Active Storage attachment" do
      it "has og_image attachment" do
        expect(post).to respond_to(:og_image)
        expect(post.og_image).to be_a(ActiveStorage::Attached::One)
      end
    end
  end
end
