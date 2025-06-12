require "system_helper"

RSpec.describe "Adding a post", type: :system do
  include EditorHelpers
  fixtures :panda_cms_users

  before do
    login_as_admin
    visit panda_cms.admin_posts_path
    click_link "Add Post"
    wait_for_editor
  end

  it "creates a new post with EditorJS content and maintains content after update", :editorjs do
    fill_in "Title", with: "Test Post"
    fill_in "URL", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote", "Test caption")

    click_button "Create Post"

    expect(page).to have_content("The post was successfully created!", wait: 1)
    expect(page).to have_content("Test Post", wait: 1)

    # Find the newly created post
    post = Panda::CMS::Post.find_by!(title: "Test Post")

    expect_editor_content_to_include("Test Header", post)
    expect_editor_content_to_include("Test content", post)
    expect_editor_content_to_include("Item 1", post)
    expect_editor_content_to_include("Item 2", post)
    expect_editor_content_to_include("Test quote", post)
  end

  it "preserves content when validation fails" do
    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote", "Test caption")

    click_button "Create Post"

    expect(page).to have_content("Title can't be blank", wait: 1)
    expect_editor_content_to_include("Test Header")
    expect_editor_content_to_include("Test content")
    expect_editor_content_to_include("Item 1")
    expect_editor_content_to_include("Item 2")
    expect_editor_content_to_include("Test quote")
  end
end
