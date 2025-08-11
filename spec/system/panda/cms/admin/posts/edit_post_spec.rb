# frozen_string_literal: true

require "system_helper"

RSpec.describe "Editing a post", type: :system do
  before do
    # Create users first
    @admin = create_admin_user
    @regular = create_regular_user
    
    # Create post programmatically
    @post = Panda::CMS::Post.create!(
      title: "Test Post 1",
      slug: "/#{Time.current.strftime("%Y/%m")}/test-post-1",
      status: "active",
      user: @admin,
      author: @admin,
      published_at: Time.current,
      content: {
        "time" => Time.current.to_i * 1000,
        "blocks" => [
          {"type" => "header", "data" => {"text" => "Test Header", "level" => 2}},
          {"type" => "paragraph", "data" => {"text" => "Test content"}}
        ],
        "version" => "2.28.2"
      },
      cached_content: "<h2>Test Header</h2><p>Test content</p>"
    )
    
    login_as_admin
  end

  let(:post) { @post }

  it "updates an existing post", :editorjs do
    visit "/admin/cms/posts/#{post.id}/edit"
    # Use JavaScript evaluation instead of CSS selector to avoid Ferrum issues
    using_wait_time(10) do
      editor_exists = page.evaluate_script("document.querySelector(\"[data-controller='editor-form'] .codex-editor\") !== null")
      expect(editor_exists).to be(true)
    end

    fill_in "Title", with: "Updated Test Post"
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
    expect(page).to have_css(".flash-message-text", text: "The post was successfully updated", wait: 5)

    post.reload
    blocks = post.content["blocks"]
    expect(blocks.first).to eq(
      "type" => "header",
      "data" => {
        "text" => "Updated Header",
        "level" => 2
      }
    )
  end

  it "shows validation errors", :editorjs do
    visit "/admin/cms/posts/#{post.id}/edit"
    # Use JavaScript evaluation instead of CSS selector to avoid Ferrum issues
    using_wait_time(10) do
      editor_exists = page.evaluate_script("document.querySelector(\"[data-controller='editor-form'] .codex-editor\") !== null")
      expect(editor_exists).to be(true)
    end

    fill_in "Title", with: ""
    click_button "Update Post"

    expect(page).to have_css(".flash-message-text", text: "Title can't be blank", wait: 5)
  end
end
