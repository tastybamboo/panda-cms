# frozen_string_literal: true

RSpec.shared_context "with fixture pages" do
  fixtures :all

  # All data is loaded from fixtures automatically
  # We just need to provide helper methods to access the fixture data

  let(:homepage_template) { panda_cms_templates(:homepage_template) }
  let(:page_template) { panda_cms_templates(:page_template) }
  let(:different_page_template) { panda_cms_templates(:different_page_template) }

  let(:admin_user) { panda_core_users(:admin_user) }
  let(:regular_user) { panda_core_users(:regular_user) }

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }
  let(:services_page) { panda_cms_pages(:services_page) }
  let(:about_team_page) { panda_cms_pages(:about_team_page) }
  let(:custom_page) { panda_cms_pages(:custom_page) }

  # Helper method to get available templates (excluding those at max capacity)
  def available_templates
    Panda::CMS::Template.available
  end

  # Helper method to verify fixture data is loaded correctly
  def verify_fixture_data
    expect(Panda::CMS::Template.count).to be >= 3
    expect(Panda::CMS::Page.count).to be >= 5
    expect(Panda::Core::User.count).to be >= 2
    expect(homepage.path).to eq("/")
    expect(homepage_template.max_uses).to eq(1)
  end
end

# Shared context for tests that need template and block setup for forms
RSpec.shared_context "with fixture pages and templates" do
  include_context "with fixture pages"

  before(:each) do
    # Skip redirect creation during test data setup
    allow_any_instance_of(Panda::CMS::Page).to receive(:create_redirect_if_path_changed).and_return(true)

    # Mock file reading for generate_missing_blocks
    setup_template_file_mocks

    # Generate missing blocks for all templates to support editor tests
    Panda::CMS::Template.generate_missing_blocks

    # Reset counter cache after fixture loading
    Panda::CMS::Template.reset_counter_cache
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
      <h2>Homepage Layout</h2>
      <%= render Panda::CMS::RichTextComponent.new(key: :hero_content) %>
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          document.body.insertAdjacentHTML('beforeend', '<p>Hello, Stimulus!</p>');
        });
      </script>
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
end
