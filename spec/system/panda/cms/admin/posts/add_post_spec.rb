require "system_helper"

RSpec.describe "Adding a post", type: :system do
  include EditorHelpers

  let(:admin_user) { create(:panda_cms_admin_user) }

  before do
    login_as_admin
    visit "/admin/posts/new"
  end

  it "creates a new post with EditorJS content and maintains content after updates" do
    # Fill in the basic post details
    fill_in "Title", with: "Test Post"
    # Slug will be auto-generated

    # Add content to the editor
    add_editor_paragraph("This is a test post")
    add_editor_paragraph("With multiple paragraphs")

    # Save the post
    click_button "Create Post"
    expect(page).to have_text("The post was successfully created!")

    # Verify the content structure
    post = Panda::CMS::Post.last
    expect(post.content).to be_a(Hash)
    expect(post.content["blocks"]).to be_an(Array)
    expect(post.content["blocks"].length).to eq(2)
    expect(post.content["blocks"][0]["data"]["text"]).to eq("This is a test post")
    expect(post.content["blocks"][1]["data"]["text"]).to eq("With multiple paragraphs")

    # Edit the first paragraph
    add_editor_paragraph("This is an updated test post", replace_first: true)

    # Save immediately
    click_button "Update Post"
    expect(page).to have_text("The post was successfully updated!")

    # Verify the content is still properly structured
    post.reload
    expect(post.content).to be_a(Hash)
    expect(post.content["blocks"]).to be_an(Array)
    expect(post.content["blocks"].length).to eq(2)
    expect(post.content["blocks"][0]["data"]["text"]).to eq("This is an updated test post")
    expect(post.content["blocks"][1]["data"]["text"]).to eq("With multiple paragraphs")
  end

  it "preserves EditorJS content when validation fails" do
    # Fill in the post details but leave title blank to trigger validation error
    add_editor_paragraph("This is a test post")
    add_editor_paragraph("That will fail validation")

    # Try to save - should fail due to missing title
    click_button "Create Post"
    expect(page).to have_text("Title can't be blank")

    # Verify the editor still shows our content
    expect_editor_content_to_include("This is a test post")
    expect_editor_content_to_include("That will fail validation")

    # Now fill in the title and save
    fill_in "Title", with: "Test Post"
    click_button "Create Post"
    expect(page).to have_text("The post was successfully created!")

    # Verify the content was saved correctly
    post = Panda::CMS::Post.last
    expect(post.content).to be_a(Hash)
    expect(post.content["blocks"]).to be_an(Array)
    expect(post.content["blocks"].length).to eq(2)
    expect(post.content["blocks"][0]["data"]["text"]).to eq("This is a test post")
    expect(post.content["blocks"][1]["data"]["text"]).to eq("That will fail validation")
  end
end
