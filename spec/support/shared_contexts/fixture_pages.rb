RSpec.shared_context "with fixture pages" do
  # All data is loaded from fixtures automatically via global_fixtures in rails_helper
  # We just need to provide helper methods to access the fixture data

  let(:homepage_template) { panda_cms_templates(:homepage_template) }
  let(:page_template) { panda_cms_templates(:page_template) }
  let(:different_page_template) { panda_cms_templates(:different_page_template) }

  let(:admin_user) { panda_cms_users(:admin_user) }
  let(:regular_user) { panda_cms_users(:regular_user) }

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
    expect(Panda::CMS::User.count).to be >= 2
    expect(homepage.path).to eq("/")
    expect(homepage_template.max_uses).to eq(1)
  end
end
