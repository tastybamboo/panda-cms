require "system_helper"

RSpec.describe "Admin Posts", type: :system do
  before do
    login_as_admin
    @other_admin = create(:panda_cms_user, admin: true)
  end

  describe "creating a post" do
    before { visit admin_posts_path }

    it "creates a new post with editor content" do
      click_on "Add Post"

      # Wait for page to load
      expect(page).to have_current_path(new_admin_post_path)
      expect(page).to have_content("Add Post")

      # Fill in form fields
      fill_in "post[title]", with: "Test Post"
      fill_in "post[slug]", with: "/test-post"
      select @other_admin.name, from: "post[user_id]"
      fill_in "post[published_at]", with: Time.current.strftime("%Y-%m-%dT%H:%M")
      select "Active", from: "post[status]"

      debug "Before waiting for editor" if ENV["DEBUG"]

      # Wait for editor to be ready
      wait_for_editor

      debug "After editor initialization" if ENV["DEBUG"]
      debug "Editor state: #{page.evaluate_script('window.editor ? { isReady: window.editor.isReady, blockCount: window.editor.blocks?.getBlocksCount() } : null')}" if ENV["DEBUG"]

      if ENV['DEBUG']
        debug_editor
      end

      # Add content using our helpers
      add_editor_header("Test Header")

      debug "After adding header" if ENV["DEBUG"]
      debug "Editor blocks: #{page.evaluate_script('window.editor.blocks.getBlocksCount()')}" if ENV["DEBUG"]

      add_editor_paragraph("This is a test paragraph")

      # Test both list types
      add_editor_list(["First unordered item", "Second unordered item"])
      add_editor_paragraph("This is a test paragraph between lists")
      add_editor_list(["First ordered item", "Second ordered item"], type: :ordered)

      add_editor_quote("Important quote", "Famous Person")

      debug "Before form submission" if ENV["DEBUG"]
      debug "Final editor state: #{page.evaluate_script('window.editor.save()')}" if ENV["DEBUG"]

      # Submit the form
      click_button "Create Post"

      expect(page).to have_text("Post was successfully created", wait: 5)

      # Verify the content was saved
      post = Panda::CMS::Post.last
      expect(post.content).to be_a(Hash)
      expect(post.content["blocks"]).to include(
        include("type" => "header", "data" => include("text" => "Test Header")),
        include("type" => "paragraph", "data" => include("text" => "This is a test paragraph")),
        include("type" => "list", "data" => include(
          "style" => "unordered",
          "items" => include("First unordered item", "Second unordered item")
        )),
        include("type" => "paragraph", "data" => include("text" => "This is a test paragraph between lists")),
        include("type" => "list", "data" => include(
          "style" => "ordered",
          "items" => include("First ordered item", "Second ordered item")
        )),
        include("type" => "quote", "data" => include("text" => "Important quote", "caption" => "Famous Person"))
      )

      # Verify the rendered content
      expect_editor_to_have_content("Test Header")
      expect_editor_to_have_content("This is a test paragraph")
      expect_editor_to_have_unordered_list(["First unordered item", "Second unordered item"])
      expect_editor_to_have_content("This is a test paragraph between lists")
      expect_editor_to_have_ordered_list(["First ordered item", "Second ordered item"])
      expect_editor_to_have_content("Important quote")
      expect_editor_to_have_content("Famous Person")
    end

    it "preserves editor content when form has validation errors" do
      click_on "Add Post"

      # Wait for editor to be ready
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor", wait: 10)
      wait_for_editor

      # Debug initial editor state
      if ENV['DEBUG']
        debug "Initial editor state:"
        debug_editor
      end

      # Add content but leave required fields empty
      add_editor_header("Content that should persist")

      # Debug after adding content
      if ENV['DEBUG']
        debug "After adding content:"
        debug_editor
      end

      # Verify content was added successfully
      expect(page).to have_content("Content that should persist")

      # Get the editor content before submission
      if ENV['DEBUG']
        content_before = page.evaluate_script('window.editor.save()')
        debug "Editor content before submission: #{content_before.inspect}"
      end

      # Submit without title but with a valid path
      fill_in "post[slug]", with: "/test-post"
      click_button "Create Post"

      # Wait for the page to reload after submission
      expect(page).to have_content("Title can't be blank")

      # Add a longer wait to ensure editor is fully reloaded
      sleep(1) if ENV['DEBUG'] # Add a small delay in debug mode
      wait_for_editor

      # Debug editor state after reload
      if ENV['DEBUG']
        debug "Editor state after reload:"
        debug_editor
      end

      # Get the editor content after reload
      if ENV['DEBUG']
        content_after = page.evaluate_script('window.editor.save()')
        debug "Editor content after reload: #{content_after.inspect}"
      end

      # Verify editor content is preserved
      expect_editor_to_have_content("Content that should persist")
    end
  end

  describe "editing a post" do
    let!(:post) { create(:panda_cms_post, title: "Original Post Title") }

    it "updates an existing post with new editor content" do
      visit edit_admin_post_path(post.admin_param)

      # Wait for page to load and editor to be ready
      expect(page).to have_current_path(edit_admin_post_path(post))
      wait_for_editor

      # Update form fields
      fill_in "post[title]", with: "Updated Test Post"
      fill_in "post[slug]", with: "/updated-test-post"

      # Clear existing content and add new content
      clear_editor
      add_editor_header("Updated Header")
      add_editor_paragraph("Updated content for testing")

      # Submit the form
      click_button "Update Post"

      expect(page).to have_text("The post was successfully updated", wait: 5)

      # Verify the content was updated
      post.reload
      expect(post.content["blocks"]).to include(
        include("type" => "header", "data" => include("text" => "Updated Header")),
        include("type" => "paragraph", "data" => include("text" => "Updated content for testing"))
      )
    end

    it "preserves editor content when update has validation errors" do
      visit edit_admin_post_path(post.admin_param)

      # Wait for editor to be ready
      expect(page).to have_css("[data-controller='editor-form'] .codex-editor", wait: 10)
      wait_for_editor

      # Clear title (required field) and add new content
      fill_in "post[title]", with: ""
      add_editor_header("This content should persist")

      # Submit the form
      click_button "Update Post"

      # Verify error and content persistence
      expect(page).to have_content("Title can't be blank")
      expect_editor_to_have_content("Original Header")
      expect_editor_to_have_content("Original content")
      expect_editor_to_have_content("This content should persist")

      # Fix the error and resubmit
      fill_in "post[title]", with: "Fixed Title"
      click_button "Update Post"

      # Verify success and content persistence
      expect(page).to have_text("The post was successfully updated!")
      post.reload
      expect(post.content["blocks"]).to include(
        include("type" => "header", "data" => include("text" => "Original Header")),
        include("type" => "paragraph", "data" => include("text" => "Original content")),
        include("type" => "header", "data" => include("text" => "This content should persist"))
      )
    end
  end
end
