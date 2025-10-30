module Panda
  module CMS
    module ApplicationHelper
      #
      # Helper method to render a ViewComponent
      # @see ViewComponent::Rendering#render
      # @usage <%= component "example", title: "Hello World!" %>
      #
      def component(name, *, **, &)
        component = name.to_s.camelize.constantize::Component
        render(component.new(*, **), &)
      end

      # TODO: Expose this elsewhere later, or you have to include helpers
      # in the calling application
      def title_tag
        if @breadcrumbs.present?
          "#{@breadcrumbs.last&.name} &middot; #{Panda::CMS.config.title}".html_safe
        elsif @title.present?
          "#{@title} &middot; #{Panda::CMS.config.title}".html_safe
        else
          Panda::CMS.config.title
        end
      end

      def panda_cms_editor
        if Panda::Core::Current.user&.admin
          content_tag(:a, "🐼", href: edit_admin_cms_page_url(Panda::CMS::Current.page), class: "text-3xl inline absolute right-2 top-2")
        end
      end

      def active_link?(path, match: :starts_with)
        if match == :starts_with
          return request.path.starts_with?(path)
        elsif match == :exact
          return request.path == path
        end

        false
      end

      def block_link_to(name = nil, options = nil, html_options = {}, &)
        html_options[:class] = "block-link"
        link_to(name, options, html_options, &)
      end

      def panda_cms_collection(slug, include_unpublished: false)
        Panda::CMS::Features.require!(:collections)
        Panda::CMS::Collections.fetch(slug, include_unpublished: include_unpublished)
      end

      def panda_cms_collection_items(slug, include_unpublished: false)
        Panda::CMS::Features.require!(:collections)
        Panda::CMS::Collections.items(slug, include_unpublished: include_unpublished)
      end

      def panda_cms_feature_enabled?(name)
        Panda::CMS::Features.enabled?(name)
      end

      def panda_cms_form_with(**options, &)
        options[:builder] = Panda::Core::FormBuilder
        options[:class] = ["block visible p-6 bg-mid/5 rounded-lg border-mid border", options[:class]].compact.join(" ")
        form_with(**options, &)
      end

      def nav_class(mode)
        if mode == "mobile"
          "-mx-3 block rounded-lg px-3 py-2 font-semibold leading-6 text-white hover:text-white hover:underline focus:underline"
        else
          "font-semibold leading-6 text-white hover:text-white hover:underline focus:underline"
        end
      end

      def selected_nav_highlight_colour_classes(request)
        "bg-mid text-white relative flex transition-all py-3 px-2 mb-2 rounded-md group flex gap-x-3 rounded-md text-base leading-6 font-normal "
      end

      def nav_highlight_colour_classes(request)
        "text-white hover:bg-mid/60 transition-all group flex gap-x-3 py-3 px-2 mb-2 rounded-md text-base leading-6 font-normal "
      end

      def level_indent(level)
        case level
        when 0
          "ml-0"
        when 1
          "ml-4"
        when 2
          "ml-8"
        when 3
          "ml-12"
        when 4
          "ml-16"
        when 5
          "ml-20"
        when 6
          "ml-24"
        when 7
          "ml-28"
        when 8
          "ml-32"
        when 9
          "ml-36"
        when 10
          "ml-40" # We can go to 72...
        else
          "ml-48"
        end
      end

      def table_indent(item_with_level_attribute)
        level_indent(item_with_level_attribute.level)
      end

      def menu_indent(item_with_level_attribute, indent_with: "pl-")
        case item_with_level_attribute.level
        when 0
          "#{indent_with}0"
        when 1
          "#{indent_with}4"
        when 2
          "#{indent_with}8"
        when 3
          "#{indent_with}12"
        when 4
          "#{indent_with}16"
        else
          "#{indent_with}20"
        end
      end
    end
  end
end
