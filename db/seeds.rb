# frozen_string_literal: true

generator = Panda::CMS::DemoSiteGenerator.new
generator.create_templates
generator.create_pages
generator.create_menus
Panda::CMS::Template.generate_missing_blocks
