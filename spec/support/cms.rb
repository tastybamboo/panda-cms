RSpec.configure do |config|
  # Set up Current attributes and URL configuration after Capybara is ready
  config.before(:each, type: :system) do
    Panda::CMS::Current.page = nil
    Panda::CMS.config.url = Panda::CMS::Current.root

    # Ensure templates have blocks generated if using fixtures
    if defined?(Panda::CMS::Template) && Panda::CMS::Template.respond_to?(:generate_missing_blocks)
      Panda::CMS::Template.generate_missing_blocks
    end
  end
end

# Configure fixture set class name mapping for namespaced models
# This tells Rails which model class to use for each fixture file
module PandaCmsFixtures
  def self.get_class_name(fixture_set_name)
    case fixture_set_name
      # panda_core_users fixtures are not supported - users must be created programmatically
    when "panda_cms_posts" then "Panda::CMS::Post"
    when "panda_cms_pages" then "Panda::CMS::Page"
    when "panda_cms_templates" then "Panda::CMS::Template"
    when "panda_cms_blocks" then "Panda::CMS::Block"
    when "panda_cms_block_contents" then "Panda::CMS::BlockContent"
    when "panda_cms_menus" then "Panda::CMS::Menu"
    when "panda_cms_menu_items" then "Panda::CMS::MenuItem"
    when "panda_cms_forms" then "Panda::CMS::Form"
    end
  end
end

# Override ActiveRecord::FixtureSet to use our mapping
module ActiveRecord
  class FixtureSet
    alias_method :original_model_class, :model_class

    def model_class
      if (klass = PandaCmsFixtures.get_class_name(@name))
        klass.constantize
      else
        original_model_class
      end
    end
  end
end
