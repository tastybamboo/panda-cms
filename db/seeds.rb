# frozen_string_literal: true

generator = Panda::CMS::DemoSiteGenerator.new
generator.create_templates
generator.create_pages
generator.create_menus
Panda::CMS::Template.generate_missing_blocks

if (homepage = Panda::CMS::Page.find_by(path: "/"))
  main_menu = Panda::CMS::Menu.find_by(start_page_id: homepage.id, kind: :auto)
  main_menu&.update(depth: 2)
end
