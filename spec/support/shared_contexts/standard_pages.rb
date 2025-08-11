# frozen_string_literal: true

RSpec.shared_context "with standard pages" do
  before(:each) do
    # Skip redirect creation during test data setup
    allow_any_instance_of(Panda::CMS::Page).to receive(:create_redirect_if_path_changed).and_return(true)

    # Mock file reading for generate_missing_blocks
    setup_template_file_mocks

    create_standard_test_data
    Panda::CMS::Template.reset_counter_cache
  end

  # Define let! variables so they're accessible in tests
  let!(:homepage_template) do
    @homepage_template ||= Panda::CMS::Template.find_or_create_by!(
      name: "Homepage",
      file_path: "layouts/homepage",
      max_uses: 1
    )
  end

  let!(:page_template) do
    @page_template ||= Panda::CMS::Template.find_or_create_by!(
      name: "Page",
      file_path: "layouts/page"
    )
  end

  let!(:different_page_template) do
    @different_page_template ||= Panda::CMS::Template.find_or_create_by!(
      name: "Different Page",
      file_path: "layouts/different_page",
      max_uses: 3,
      pages_count: 2
    )
  end

  let!(:admin_user) do
    @admin_user ||= Panda::Core::User.find_or_create_by!(email: "admin@example.com") do |user|
      user.firstname = "Admin"
      user.lastname = "User"
      user.admin = true
    end
  end

  let!(:regular_user) do
    @regular_user ||= Panda::Core::User.find_or_create_by!(email: "user@example.com") do |user|
      user.firstname = "Regular"
      user.lastname = "User"
      user.admin = false
    end
  end

  let!(:homepage) do
    @homepage ||= Panda::CMS::Page.find_or_create_by!(
      path: "/",
      title: "Home",
      template: homepage_template,
      status: "active"
    )
  end

  let!(:about_page) do
    @about_page ||= Panda::CMS::Page.find_or_create_by!(
      path: "/about",
      title: "About",
      template: page_template,
      parent: homepage,
      status: "active"
    )
  end

  let!(:services_page) do
    @services_page ||= Panda::CMS::Page.find_or_create_by!(
      path: "/services",
      title: "Services",
      template: page_template,
      parent: homepage,
      status: "active"
    )
  end

  let!(:about_team_page) do
    @about_team_page ||= Panda::CMS::Page.find_or_create_by!(
      path: "/about/team",
      title: "Team",
      template: page_template,
      parent: about_page,
      status: "active"
    )
  end

  let!(:custom_page) do
    @custom_page ||= Panda::CMS::Page.find_or_create_by!(
      path: "/custom-page",
      title: "Custom Page",
      template: different_page_template,
      parent: homepage,
      status: "active"
    )
  end

  def create_standard_test_data
    # Create templates first
    homepage_template
    page_template
    different_page_template

    # Create users
    admin_user
    regular_user

    # Create pages (this will trigger block creation via callbacks)
    homepage
    about_page
    services_page
    about_team_page
    custom_page

    # Generate missing blocks for all templates to support editor tests
    Panda::CMS::Template.generate_missing_blocks

    # Add sample content to block contents for website tests
    populate_block_contents
  end

  def setup_template_file_mocks
    # Mock Dir.glob to return the layout files
    allow(Dir).to receive(:glob).and_return([
      "app/views/layouts/page.html.erb",
      "app/views/layouts/homepage.html.erb",
      "app/views/layouts/different_page.html.erb"
    ])

    # Mock the content of each layout file
    page_content = <<~ERB
      <%= render "shared/header" %>
      <h1><%= @page.title %></h1>
      <h2>Basic Page Layout</h2>
      <%= render Panda::CMS::TextComponent.new(key: :plain_text) %>
      <%= render Panda::CMS::CodeComponent.new(key: :html_code) %>
      <%= render Panda::CMS::RichTextComponent.new(key: :main_content) %>
      <%= yield %>
      <%= render "shared/footer" %>
    ERB

    homepage_content = <<~ERB
      <%= render "shared/header" %>
      <h1><%= @page.title %></h1>
      <%= render Panda::CMS::RichTextComponent.new(key: :hero_content) %>
      <%= yield %>
      <%= render "shared/footer" %>
    ERB

    different_page_content = <<~ERB
      <%= render "shared/header" %>
      <h1><%= @page.title %></h1>
      <%= render Panda::CMS::TextComponent.new(key: :sidebar) %>
      <%= render Panda::CMS::RichTextComponent.new(key: :content) %>
      <%= yield %>
      <%= render "shared/footer" %>
    ERB

    # Allow File.open to work normally for most files, but mock specific layout files
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with("app/views/layouts/page.html.erb").and_return(StringIO.new(page_content))
    allow(File).to receive(:open).with("app/views/layouts/homepage.html.erb").and_return(StringIO.new(homepage_content))
    allow(File).to receive(:open).with("app/views/layouts/different_page.html.erb").and_return(StringIO.new(different_page_content))
  end

  def populate_block_contents
    # Add content to about page blocks for website tests
    about_page = Panda::CMS::Page.find_by(path: "/about")
    return unless about_page

    # Find block contents and add sample content
    plain_text_content = about_page.block_contents.joins(:block).find_by(panda_cms_blocks: {key: "plain_text"})
    plain_text_content&.update!(content: "Here is some plain text content")

    html_code_content = about_page.block_contents.joins(:block).find_by(panda_cms_blocks: {key: "html_code"})
    html_code_content&.update!(
      content: "<p><strong>Here is some HTML code.</strong></p>",
      cached_content: "<p><strong>Here is some HTML code.</strong></p>"
    )

    main_content_content = about_page.block_contents.joins(:block).find_by(panda_cms_blocks: {key: "main_content"})
    if main_content_content
      editor_js_content = {
        "time" => Time.current.to_i * 1000,
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {
              "text" => "This is the main content of the about page"
            }
          }
        ],
        "version" => "2.30.7",
        "source" => "editorJS"
      }
      main_content_content.update!(
        content: editor_js_content,
        cached_content: "<p>This is the main content of the about page</p>"
      )
    end

    # Add content to homepage blocks
    homepage = Panda::CMS::Page.find_by(path: "/")
    return unless homepage

    hero_content = homepage.block_contents.joins(:block).find_by(panda_cms_blocks: {key: "hero_content"})
    return unless hero_content

    editor_js_content = {
      "time" => Time.current.to_i * 1000,
      "blocks" => [
        {
          "type" => "paragraph",
          "data" => {
            "text" => "I like ice cream!"
          }
        }
      ],
      "version" => "2.30.7",
      "source" => "editorJS"
    }
    hero_content.update!(
      content: editor_js_content,
      cached_content: "<p>I like ice cream!</p>"
    )
  end
end
