module FixtureHelpers
  # Map of fixture method names to model classes
  FIXTURE_MODELS = {
    panda_cms_pages: Panda::CMS::Page,
    panda_cms_templates: Panda::CMS::Template,
    panda_cms_blocks: Panda::CMS::Block,
    panda_cms_block_contents: Panda::CMS::BlockContent,
    panda_cms_users: Panda::CMS::User,
    panda_cms_menus: Panda::CMS::Menu,
    panda_cms_menu_items: Panda::CMS::MenuItem,
    panda_cms_posts: Panda::CMS::Post
  }

  # Dynamically handle fixture access methods
  def method_missing(method_name, *args, &block)
    if FIXTURE_MODELS.key?(method_name)
      fixture_name = args.first
      table_name = method_name
      model_class = FIXTURE_MODELS[method_name]

      begin
        model_class.find(ActiveRecord::FixtureSet.identify(fixture_name, table_name))
      rescue => e
        raise "Could not find fixture #{fixture_name} for #{table_name}: #{e.message}"
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    FIXTURE_MODELS.key?(method_name) || super
  end
end
