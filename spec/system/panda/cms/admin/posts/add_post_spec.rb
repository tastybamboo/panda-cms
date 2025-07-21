# frozen_string_literal: true

require "system_helper"

RSpec.describe "Adding a post", type: :system do
  fixtures :panda_cms_users

  before do
    login_as_admin
    
    if ENV["CI"]
      posts_path = panda_cms.admin_posts_path rescue "/admin/posts"
      puts "[Route Debug] admin_posts_path resolved to: #{posts_path}"
      puts "[Route Debug] Current path before visit: #{page.current_path}"
      puts "[Route Debug] Current URL before visit: #{page.current_url}"
    end
    
    visit panda_cms.admin_posts_path

    if ENV["CI"]
      puts "[Route Debug] Current path after visit: #{page.current_path}"
      puts "[Route Debug] Current URL after visit: #{page.current_url}"  
      puts "[Route Debug] Page title after visit: #{page.title}"
    end

    # Wait for page to fully load and ensure "Add Post" link is present
    expect(page).to have_text("Posts", wait: 10)
    expect(page).to have_link("Add Post", wait: 10)

    click_link "Add Post"

    # Wait for new page form to load
    expect(page).to have_text("Add Post", wait: 10)
    expect(page).to have_field("Title", wait: 5)
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
