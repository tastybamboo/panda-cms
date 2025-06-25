# frozen_string_literal: true

require "system_helper"

RSpec.describe "Adding a post", type: :system do
  fixtures :panda_cms_users

  before do
    login_as_admin
    visit panda_cms.admin_posts_path
    click_link "Add Post"
  end

  it "creates a new post with valid details" do
    fill_in "Title", with: "Test Post"
    fill_in "URL", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    click_button "Create Post"

    expect(page).to have_content("The post was successfully created!", wait: 1)
    expect(page).to have_content("Test Post", wait: 1)

    # Verify the post was created in the database
    post = Panda::CMS::Post.find_by!(title: "Test Post")
    expect(post.slug).to eq("/#{Time.current.strftime("%Y/%m")}/test-post")
  end

  it "shows validation errors when title is missing" do
    # Don't fill in title
    fill_in "URL", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    click_button "Create Post"

    expect(page).to have_content("Title can't be blank", wait: 1)
  end

  it "shows validation errors when URL is missing" do
    fill_in "Title", with: "Test Post"
    # Don't fill in URL

    click_button "Create Post"

    expect(page).to have_content("URL can't be blank", wait: 1)
  end

  it "shows the add post form with required fields" do
    expect(page).to have_content("Add Post")
    expect(page).to have_field("Title")
    expect(page).to have_field("URL")
    expect(page).to have_button("Create Post")
  end
end
