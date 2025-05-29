module Panda
  module CMS
    class DemoSiteGenerator
      attr_accessor :menus, :pages, :templates

      def initialize
        @menus = {}
        @pages = {}
        @templates = {}
      end

      #
      # Creates initial templates and empty blocks
      #
      # @return void
      def create_templates
        # Templates
        initial_templates = [
          {name: "Homepage", file_path: "layouts/homepage"},
          {name: "Page", file_path: "layouts/page"}
        ]

        initial_templates.each do |template|
          key = template[:name].downcase.to_sym
          @templates[key] = Panda::CMS::Template.find_or_create_by(template)
        end

        @templates[:homepage].update(max_uses: 1)
        @templates
      end

      #
      # Creates initial pages
      #
      # @return [Hash] A hash containing the created pages
      def create_pages
        @pages[:home] = Panda::CMS::Page.find_or_create_by({
          path: "/",
          title: "Home",
          panda_cms_template_id: @templates[:homepage].id
        })
        @pages[:about] = Panda::CMS::Page.find_or_create_by({
          path: "/about",
          title: "About",
          panda_cms_template_id: @templates[:page].id,
          parent: @pages[:home]
        })
        @pages[:not_found] = Panda::CMS::Page.find_or_create_by({
          path: "/404",
          title: "Page Not Found",
          panda_cms_template_id: @templates[:page].id,
          parent: @pages[:home],
          status: "hidden"
        })
        @pages[:internal_error] = Panda::CMS::Page.find_or_create_by({
          path: "/500",
          title: "Internal Server Error",
          panda_cms_template_id: @templates[:page].id,
          parent: @pages[:home],
          status: "hidden"
        })

        Panda::CMS::Page.reset_column_information
        Panda::CMS::Page.rebuild!

        @pages
      end

      #
      # Creates initial menus
      #
      # @return [Hash] A hash containing the created menus
      def create_menus
        @menus = {}
        @menus[:main] = Panda::CMS::Menu.find_or_create_by(name: "Main Menu")
        @menus[:footer] = Panda::CMS::Menu.find_or_create_by(name: "Footer Menu")

        # Automatically create main menu from homepage
        unless @pages[:home].nil?
          @menus[:main].update(kind: :auto, start_page: @pages[:home], depth: 1)
          @menus[:main].generate_auto_menu_items
        end

        @menus
      end
    end
  end
end
