# frozen_string_literal: true

require "system_helper"

RSpec.describe "Editing a post", type: :system do
  fixtures :panda_cms_users, :panda_cms_posts

  before do
    login_as_admin
  end

  let(:post) { panda_cms_posts(:first_post) }

  it "updates an existing post", :editorjs do
    visit "/admin/posts/#{post.id}/edit"
    expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

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
    visit "/admin/posts/#{post.id}/edit"
    expect(page).to have_css("[data-controller='editor-form'] .codex-editor")

    fill_in "Title", with: ""
    click_button "Update Post"

    expect(page).to have_css(".flash-message-text", text: "Title can't be blank", wait: 5)
  end
end
