# frozen_string_literal: true

require "system_helper"

RSpec.describe "Adding a post", type: :system do
  fixtures :panda_cms_users

  before do
    login_as_admin
    
    # Debug CI navigation issues for post page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Post test - before navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{page.status_code rescue 'unknown'}"
    end
    
    visit "/admin/posts"
    # Navigate directly to add post page to avoid DOM node issues
    visit "/admin/posts/new"
    
    # Debug CI navigation issues for post page
    if ENV["GITHUB_ACTIONS"] == "true"
      puts "\n[CI Debug] Post test - after navigation:"
      puts "   Current URL: #{page.current_url}"
      puts "   Page title: #{page.title}"
      puts "   Status code: #{page.status_code rescue 'unknown'}"
      puts "   Page content length: #{page.html.length}"
      puts "   Page contains 'Add Post': #{page.html.include?('Add Post')}"
      
      if page.current_url.include?('about:blank') || page.html.length < 100
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
    unique_title = "Test Post #{Time.now.to_i}"
    unique_slug = "/#{Time.current.strftime("%Y/%m")}/test-post-#{Time.now.to_i}"
    
    # Use safe form helpers to avoid Ferrum browser reset issues
    safe_fill_in "post_title", with: unique_title
    safe_fill_in "post_slug", with: unique_slug

    # Set the content field with valid EditorJS content
    content_json = {
      time: Time.now.to_i,
      blocks: [{type: 'paragraph', data: {text: 'Test content'}}],
      version: '2.28.2',
      source: 'editorJS'
    }.to_json
    
    page.execute_script("
      var hiddenField = document.querySelector('input[name=\"post[content]\"]');
      if (hiddenField) {
        hiddenField.value = #{content_json.inspect};
      }
    ")

    safe_click_button "Create Post"
    
    # Wait for redirect
    sleep 1
    
    # Check if we were redirected to login (session expired)
    if page.has_css?("#button-sign-in-google")
      # Log back in and check the posts
      login_as_admin
      visit "/admin/posts"
      # Check if the post was created
      expect(page.html).to include(unique_title)
    else
      # Check we're on the edit page (indicates successful creation and redirect)
      expect(page.current_url).to match(%r{/admin/posts/[^/]+/edit})
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
    # Don't fill in title
    safe_fill_in "post_slug", with: "/#{Time.current.strftime("%Y/%m")}/test-post"

    safe_click_button "Create Post"

    # Use string-based checks to avoid DOM node issues
    expect(page.html).to include("Title can't be blank")
  end

  it "shows validation errors when URL is missing" do
    safe_fill_in "post_title", with: "Test Post"
    # Don't fill in slug

    # Use normal button click - validation errors should be handled by JavaScript
    safe_click_button "Create Post"

    # Use string-based checks to avoid DOM node issues
    expect(page.html).to include("URL can't be blank")
  end

  it "shows the add post form with required fields" do
    # Use string-based checks for form presence
    html_content = page.html  
    expect(html_content).to include("Add Post")
    
    # Use safe helpers to avoid Ferrum browser reset issues
    safe_expect_field("post_title")
    safe_expect_field("post_slug")
    safe_expect_button("Create Post")
  end
end
