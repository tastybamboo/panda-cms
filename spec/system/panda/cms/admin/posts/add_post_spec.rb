# frozen_string_literal: true

require "system_helper"

RSpec.describe "Adding a post", type: :system do
  before do
    login_as_admin

    # Debug CI navigation issues for post page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Post test - before navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{begin
        page.status_code
      rescue
        "unknown"
      end}"
    end

    visit "/admin/cms/posts"
    # Navigate directly to add post page to avoid DOM node issues
    visit "/admin/cms/posts/new"

    # Debug CI navigation issues for post page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Post test - after navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{begin
        page.status_code
      rescue
        "unknown"
      end}"
      puts "   Page content length: #{page.html.length}"
      puts "   Page contains 'Add Post': #{page.html.include?("Add Post")}"

      if page.current_url.include?("about:blank") || page.html.length < 100
        puts "   ❌ Post page didn't load properly"
        puts "   First 500 chars of HTML: #{page.html[0..500]}"
        fail "Post page navigation failed in CI"
      end
    end

    expect(page.html).to include("Add Post")

    # Add extra stability wait in CI environment
    if ENV["GITHUB_ACTIONS"] == "true"
      sleep(1)
    end
  end

  it "creates a new post with valid details" do
    # Ensure clean state for this test
    visit "/admin/cms/posts/new"

    # Wait for JavaScript to load
    # Add a small wait to ensure JavaScript executes
    sleep 1

    # Check if JavaScript loaded
    js_loaded = begin
      page.evaluate_script("window.pandaCmsLoaded")
    rescue
      nil
    end
    puts "JavaScript loaded: #{js_loaded}" if ENV["DEBUG"]

    timestamp = Time.now.to_i
    unique_title = "Test Post #{timestamp}"
    # Use the expected date-based format for posts
    unique_slug = "/#{Time.current.strftime("%Y/%m")}/test-post-#{timestamp}"

    # Fill in the slug first to avoid JavaScript auto-generation
    if ENV["GITHUB_ACTIONS"]
      safe_fill_in "post_slug", with: unique_slug
      safe_fill_in "post_title", with: unique_title
    else
      fill_in "post_slug", with: unique_slug
      fill_in "post_title", with: unique_title
    end

    # Set the content field with valid EditorJS content
    content_json = {
      time: Time.now.to_i,
      blocks: [{type: "paragraph", data: {text: "Test content"}}],
      version: "2.28.2",
      source: "editorJS"
    }.to_json

    page.execute_script("
      var hiddenField = document.querySelector('input[name=\"post[content]\"]');
      if (hiddenField) {
        hiddenField.value = #{content_json.inspect};
      }
    ")

    if ENV["GITHUB_ACTIONS"]
      safe_click_button "Create Post"
    else
      click_button "Create Post"
    end

    # Wait for redirect
    sleep 1

    # Check if we were redirected to login (session expired)
    if page.has_css?("#button-sign-in-google_oauth2")
      # Log back in and check the posts
      login_as_admin
      visit "/admin/cms/posts"
      # Check if the post was created
      expect(page.html).to include(unique_title)
    else
      # Check we're on the edit page (indicates successful creation and redirect)
      expect(page.current_url).to match(%r{/admin/cms/posts/[^/]+/edit})
      # Check the page shows we're editing the created post
      expect(page).to have_button("Update Post")
      html_content = page.html
      expect(html_content).to include(unique_title)
    end

    # Verify the post was created in the database
    post = Panda::CMS::Post.find_by(title: unique_title)
    if post.nil?
      puts "Post not found! All posts: #{Panda::CMS::Post.all.map(&:title)}"
      puts "Current URL: #{page.current_url}"
      puts "Page content snippet: #{page.html[0..500]}"
    end
    expect(post).not_to be_nil
    expect(post.slug).to eq(unique_slug)
  end

  it "shows validation errors when title is missing" do
    # REQUIRED: Clean state for validation test (see docs/developers/testing/validation-testing.md)
    visit "/admin/cms/posts/new"
    sleep 1  # Allow page to stabilize

    # Wait for EditorJS to initialize and enable the submit button
    expect(page).to have_button("Create Post", disabled: false, wait: 10)

    # Fill valid fields, omit the field being tested
    if ENV["GITHUB_ACTIONS"]
      safe_fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"
      safe_click_button "Create Post"
    else
      fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"
      click_button "Create Post"
    end

    # Wait for validation errors to appear
    expect(page).to have_content("Title can't be blank", wait: 5)
  end

  it "shows validation errors when URL is missing" do
    # REQUIRED: Clean state for validation test (see docs/developers/testing/validation-testing.md)
    visit "/admin/cms/posts/new"
    sleep 1  # Allow page to stabilize

    # Wait for EditorJS to initialize and enable the submit button
    expect(page).to have_button("Create Post", disabled: false, wait: 10)

    # Clear the slug field first and mark as user-edited to prevent auto-generation
    page.execute_script("
      var slugField = document.querySelector('input[name=\"post[slug]\"]');
      if (slugField) {
        slugField.value = '';
        slugField.dataset.userEdited = 'true';
      }
    ")

    # Fill valid fields, omit the field being tested
    fill_in "post_title", with: "Test Post"

    click_button "Create Post"

    # Wait for validation errors to appear
    expect(page).to have_content("Slug can't be blank", wait: 5)
  end

  it "shows the add post form with required fields" do
    # Ensure clean state for this test
    visit "/admin/cms/posts/new"

    # Use string-based checks for form presence
    html_content = page.html
    expect(html_content).to include("Add Post")

    # Use HTML-based checks to avoid Ferrum issues
    html_content = page.html
    expect(html_content).to include("post_title")
    expect(html_content).to include("post_slug")
    expect(html_content).to include("Create Post")
  end
end
