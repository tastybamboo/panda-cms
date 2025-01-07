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
      select @other_admin.name, from: "post[author_id]"
      fill_in "post[published_at]", with: (Time.current - 1.minute).iso8601
      select "Active", from: "post[status]"

      # Wait for editor container and input field
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

      # Add content using our helpers
      add_editor_header("Test Header")
      add_editor_paragraph("This is a test paragraph")
      add_editor_list(["First unordered item", "Second unordered item"])
      add_editor_paragraph("This is a test paragraph between lists")

      find("input[name='post[content]']", visible: false, wait: 1) do |element|
        element.value.present?
      end
      click_button "Create Post"

      expect(page).to have_text("Post was successfully created")

      post = Panda::CMS::Post.last
      expect(post.cached_content).to have_css("h2", text: "Test Header")
      expect(post.cached_content).to have_content("This is a test paragraph")
      expect(post.cached_content).to have_css("ul li", text: "First unordered item")
      expect(post.cached_content).to have_css("ul li", text: "Second unordered item")
      expect(post.cached_content).to have_content("This is a test paragraph between lists")
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
          {type: "header", data: {text: "Updated Header", level: 2}}
        ],
        version: "2.28.2"
      }
      editor_input.set(content.to_json)

      click_button "Update Post"
      expect(page).to have_text("The post was successfully updated")

      post.reload
      blocks = JSON.parse(post.content)["blocks"]
      expect(blocks.first).to eq(
        "type" => "header",
        "data" => {
          "text" => "Updated Header",
          "level" => 2
        }
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
