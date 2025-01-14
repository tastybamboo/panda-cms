require "system_helper"

RSpec.describe "Adding a post", type: :system do
  include EditorHelpers

  before do
    login_as_admin
    visit panda_cms.admin_posts_path
    click_link "Add Post"
    wait_for_editor
  end

  it "creates a new post with EditorJS content and maintains content after update" do
    fill_in "Title", with: "Test Post"
    fill_in "URL", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote")

    click_button "Create Post"

    expect(page).to have_content("The post was successfully created!")
    expect(page).to have_content("Test Post")
    expect_editor_content_to_include("Test Header")
    expect_editor_content_to_include("Test content")
    expect_editor_content_to_include("Item 1")
    expect_editor_content_to_include("Test quote")
  end

  it "preserves content when validation fails" do
    add_editor_header("Test Header")
    add_editor_paragraph("Test content")
    add_editor_list(["Item 1", "Item 2"])
    add_editor_quote("Test quote")

    click_button "Create Post"

    expect(page).to have_content("Title can't be blank")
    expect_editor_content_to_include("Test Header")
    expect_editor_content_to_include("Test content")
    expect_editor_content_to_include("Item 1")
    expect_editor_content_to_include("Test quote")
  end
end
