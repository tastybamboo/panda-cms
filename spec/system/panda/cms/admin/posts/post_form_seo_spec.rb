# frozen_string_literal: true

require "system_helper"

RSpec.describe "Post form SEO functionality", type: :system do
  fixtures :all

  let(:admin) { create_admin_user }
  let(:post) { panda_cms_posts(:first_post) }

  before do
    skip "This functionality is not yet implemented"
    post.update!(user: admin, author: admin)
    login_as_admin
    Panda::CMS::Current.root = Capybara.app_host
  end

  describe "SEO fields visibility" do
    it "shows all SEO fields in the post form" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      # SEO fields
      expect(page).to have_content("SEO Settings")
      expect(page).to have_field("SEO Title")
      expect(page).to have_field("SEO Description")
      expect(page).to have_field("SEO Keywords")
      expect(page).to have_field("Visible to search engines")
      expect(page).to have_field("Hidden from search engines")

      # Social sharing fields
      expect(page).to have_content("Social Sharing")
      expect(page).to have_field("Social Media Title")
      expect(page).to have_field("Social Media Description")
      expect(page).to have_field("Content Type")
      expect(page).to have_field("Social Media Image")
    end

    it "loads existing SEO data" do
      post.update!(
        seo_title: "Post SEO Title",
        seo_description: "Post SEO description text",
        seo_keywords: "keyword1, keyword2",
        og_title: "Post OG Title",
        og_description: "Post OG description",
        og_type: "article"
      )

      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      expect(find_field("SEO Title").value).to eq("Post SEO Title")
      expect(find_field("SEO Description").value).to eq("Post SEO description text")
      expect(find_field("SEO Keywords").value).to eq("keyword1, keyword2")
      expect(find_field("Social Media Title").value).to eq("Post OG Title")
      expect(find_field("Social Media Description").value).to eq("Post OG description")
      expect(find_field("Content Type").value).to eq("article")
    end
  end

  describe "saving SEO data" do
    it "saves SEO fields when updating a post" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "SEO Title", with: "Updated SEO Title"
      fill_in "SEO Description", with: "Updated SEO description"
      fill_in "SEO Keywords", with: "test, keywords"
      choose "Hidden from search engines"

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)

      post.reload
      expect(post.seo_title).to eq("Updated SEO Title")
      expect(post.seo_description).to eq("Updated SEO description")
      expect(post.seo_keywords).to eq("test, keywords")
      expect(post.seo_index_mode).to eq("invisible")
    end

    it "saves social sharing data when updating a post" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "Social Media Title", with: "Updated OG Title"
      fill_in "Social Media Description", with: "Updated OG description"
      select "Article", from: "Content Type"

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)

      post.reload
      expect(post.og_title).to eq("Updated OG Title")
      expect(post.og_description).to eq("Updated OG description")
      expect(post.og_type).to eq("article")
    end
  end

  describe "OG image upload with cropper" do
    it "shows the file input for OG image" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      expect(page).to have_field("Social Media Image")

      # Verify it's using the cropper (has data-controller attribute)
      image_field = find_field("Social Media Image")
      expect(image_field["data-controller"]).to eq("image-cropper")
    end

    it "has cropper data attributes configured" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      image_field = find_field("Social Media Image")

      # Check aspect ratio is set to 1.91 (1200x630)
      expect(image_field["data-image-cropper-aspect-ratio-value"]).to eq("1.91")

      # Check minimum dimensions
      expect(image_field["data-image-cropper-min-width-value"]).to eq("1200")
      expect(image_field["data-image-cropper-min-height-value"]).to eq("630")
    end

    it "shows the current OG image if one exists", skip: "Active Storage attachment display issue in test environment" do
      # Attach a test image to the post
      post.og_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.png")),
        filename: "test_image.png",
        content_type: "image/png"
      )

      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      # Should show the current image
      expect(page).to have_css("img", wait: 5)
    end
  end

  describe "character limits" do
    it "accepts SEO title within limit (70 chars)" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "SEO Title", with: "A" * 70

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end

    it "accepts SEO description within limit (160 chars)" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "SEO Description", with: "A" * 160

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end

    it "accepts OG title within limit (60 chars)" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "Social Media Title", with: "A" * 60

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end

    it "accepts OG description within limit (200 chars)" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "Social Media Description", with: "A" * 200

      click_button "Update Post"

      expect(page).to have_content(/successfully updated/i, wait: 10)
    end
  end

  describe "validation errors" do
    it "shows validation errors when SEO title is too long" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "SEO Title", with: "A" * 71

      click_button "Update Post"

      expect(page).to have_content(/too long/i, wait: 5)
    end

    it "shows validation errors when SEO description is too long" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "SEO Description", with: "A" * 161

      click_button "Update Post"

      expect(page).to have_content(/too long/i, wait: 5)
    end
  end

  describe "creating a new post with SEO data" do
    it "saves SEO data when creating a new post" do
      visit "/admin/cms/posts/new"
      expect(page).to have_content("Add Post", wait: 10)

      fill_in "Title", with: "New Post with SEO"
      fill_in "URL", with: "new-post-seo"
      fill_in "SEO Title", with: "New Post SEO Title"
      fill_in "SEO Description", with: "New post SEO description"
      fill_in "SEO Keywords", with: "new, post, test"

      click_button "Create Post"

      expect(page).to have_content(/successfully created/i, wait: 10)

      new_post = Panda::CMS::Post.where("slug LIKE ?", "%new-post-seo").first
      expect(new_post).not_to be_nil
      expect(new_post.seo_title).to eq("New Post SEO Title")
      expect(new_post.seo_description).to eq("New post SEO description")
      expect(new_post.seo_keywords).to eq("new, post, test")
    end

    it "creates post without SEO data if fields are left empty" do
      visit "/admin/cms/posts/new"
      expect(page).to have_content("Add Post", wait: 10)

      fill_in "Title", with: "Post Without SEO"
      fill_in "URL", with: "post-no-seo"

      click_button "Create Post"

      expect(page).to have_content(/successfully created/i, wait: 10)

      new_post = Panda::CMS::Post.where("slug LIKE ?", "%post-no-seo").first
      expect(new_post).not_to be_nil
      expect(new_post.seo_title).to be_blank
      expect(new_post.seo_description).to be_blank
    end
  end

  describe "SEO index mode" do
    it "sets index mode to visible by default" do
      visit "/admin/cms/posts/new"
      expect(page).to have_content("Add Post", wait: 10)

      # Default should be visible
      expect(find_field("Visible to search engines")).to be_checked

      fill_in "Title", with: "Default Index Mode Post"
      fill_in "URL", with: "default-index"

      click_button "Create Post"

      new_post = Panda::CMS::Post.where("slug LIKE ?", "%default-index").first
      expect(new_post.seo_index_mode).to eq("visible")
    end

    it "allows setting index mode to invisible" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      choose "Hidden from search engines"

      click_button "Update Post"

      post.reload
      expect(post.seo_index_mode).to eq("invisible")
    end

    it "persists index mode across edits" do
      post.update!(seo_index_mode: "invisible")

      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      expect(find_field("Hidden from search engines")).to be_checked
    end
  end

  describe "canonical URL" do
    it "allows setting a canonical URL" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "Canonical URL", with: "https://example.com/canonical-post"

      click_button "Update Post"

      post.reload
      expect(post.canonical_url).to eq("https://example.com/canonical-post")
    end

    it "validates canonical URL format" do
      visit "/admin/cms/posts/#{post.id}/edit"
      expect(page).to have_content(post.title, wait: 10)

      fill_in "Canonical URL", with: "not-a-valid-url"

      click_button "Update Post"

      expect(page).to have_content(/invalid/i, wait: 5)
    end
  end
end
