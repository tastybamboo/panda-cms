require "system_helper"

RSpec.describe "Editing a post", type: :system do
  before do
    login_as_admin
    @other_admin = create(:panda_cms_user, admin: true)
  end

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
    blocks = post.content["blocks"]
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
