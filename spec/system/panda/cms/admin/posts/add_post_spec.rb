# frozen_string_literal: true

require "system_helper"

RSpec.describe "Adding a post", type: :system do
  fixtures :panda_cms_users

  before do
    # Reset session more thoroughly for CI stability
    if ENV["CI"]
      Capybara.reset_sessions!
      sleep(1)
    end

    # Retry mechanism for CI navigation issues
    retries = ENV["CI"] ? 3 : 1
    success = false

    retries.times do |attempt|
      begin
        if ENV["CI"] && attempt > 0
          puts "[CI Retry] Attempt #{attempt + 1} for posts navigation"
          Capybara.reset_sessions!
          sleep(2)
        end

        login_as_admin

        if ENV["CI"]
          puts "[CI Debug] About to visit /admin/posts (attempt #{attempt + 1})"
          puts "[CI Debug] Current URL before visit: #{page.current_url}"
        end

        visit "/admin/posts"

        if ENV["CI"]
          puts "[CI Debug] After visiting /admin/posts"
          puts "[CI Debug] Current URL: #{page.current_url}"
          puts "[CI Debug] Page HTML length: #{page.html.length}"
        end

        # Wait for page to fully load and ensure "Add Post" link is present
        expect(page).to have_text("Posts", wait: 15)
        expect(page).to have_link("Add Post", wait: 10)

        click_link "Add Post"

        # Wait for new page form to load
        expect(page).to have_text("Add Post", wait: 10)
        expect(page).to have_field("Title", wait: 5)

        success = true
        break

      rescue => e
        if ENV["CI"]
          puts "[CI Debug] Posts attempt #{attempt + 1} failed: #{e.message}"
          puts "[CI Debug] Current URL: #{page.current_url}"
          if page.html.length < 100
            puts "[CI Debug] Page content: #{page.html}"
          end

          if attempt < retries - 1
            puts "[CI Debug] Will retry posts navigation..."
            next
          else
            puts "[CI Debug] All posts attempts failed, giving up"
            raise
          end
        else
          raise
        end
      end
    end
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
