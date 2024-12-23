require "system_helper"

RSpec.describe "Admin Posts", type: :system do
  before do
    login_as_admin
    @other_admin = create(:panda_cms_user, admin: true)
  end

  describe "creating a post" do
    before { visit admin_posts_path }

    it "creates a new post with content" do
      click_on "Add Post"
      expect(page).to have_current_path(new_admin_post_path)

      fill_in "post[title]", with: "Test Post"
      fill_in "post[slug]", with: "/test-post"
      select @other_admin.name, from: "post[user_id]"
      fill_in "post[published_at]", with: Time.current.strftime("%d/%m/%Y, %H:%M")
      select "Active", from: "post[status]"

      # Wait for editor container and input field
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

      # Add content using our helpers
      add_editor_header("Test Header")
      add_editor_paragraph("This is a test paragraph")
      add_editor_list(["First unordered item", "Second unordered item"])
      add_editor_paragraph("This is a test paragraph between lists")
      add_editor_list(["First ordered item", "Second ordered item"], type: :ordered)
      add_editor_quote("Important quote", "Famous Person")

      click_button "Create Post"
      expect(page).to have_text("Post was successfully created")

      post = Panda::CMS::Post.last
      expect(post.cached_content).to have_css("h2", text: "Test Header")
      expect(post.cached_content).to have_content("This is a test paragraph")
      expect(post.cached_content).to have_css("ul li", text: "First unordered item")
      expect(post.cached_content).to have_css("ul li", text: "Second unordered item")
      expect(post.cached_content).to have_content("This is a test paragraph between lists")
      expect(post.cached_content).to have_css("ol li", text: "First ordered item")
      expect(post.cached_content).to have_css("ol li", text: "Second ordered item")
      expect(post.cached_content).to have_css(".quote", text: "Important quote")
      expect(post.cached_content).to have_css(".quote-caption", text: "Famous Person")
    end

    it "shows validation errors" do
      click_on "Add Post"
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

      fill_in "post[slug]", with: "/test-post"
      click_button "Create Post"

      expect(page).to have_content("Title can't be blank")
    end
  end

  describe "editing a post" do
    let!(:post) { create(:panda_cms_post, title: "Original Post Title") }

    it "updates an existing post" do
      visit edit_admin_post_path(post.admin_param)
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

      fill_in "post[title]", with: "Updated Test Post"
      editor_input = find("[data-editor-form-target='hiddenField']", visible: false)

      content = {
        time: Time.now.to_i,
        blocks: [
          { type: "header", data: { text: "Updated Header", level: 2 } }
        ],
        version: "2.28.2"
      }
      editor_input.set(content.to_json)

      click_button "Update Post"
      expect(page).to have_text("The post was successfully updated")

      post.reload
      expect(post.content["blocks"]).to include(
        include("type" => "header", "data" => include("text" => "Updated Header"))
      )
    end

    it "shows validation errors" do
      visit edit_admin_post_path(post.admin_param)
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

      fill_in "post[title]", with: ""
      click_button "Update Post"

      expect(page).to have_content("Title can't be blank")
    end
  end
end
