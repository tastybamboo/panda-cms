# frozen_string_literal: true

module Panda
  module CMS
    # Base class for all ViewComponent components in Panda CMS
    # Inherits from ViewComponent::Base for all CMS components
    class Base < ::ViewComponent::Base
      # Auto-render template files for components without explicit call methods
      def call
        render_template_from_file
      end

      def render_template_from_file(template_name = nil)
        # Get the component class's file location
        component_file = self.class.instance_methods(false).first ? 
          self.class.instance_method(:initialize).source_location.first :
          __FILE__
        
        component_dir = File.dirname(component_file)
        base_name = template_name || self.class.name.demodulize.underscore
        template_path = File.join(component_dir, "#{base_name}.html.erb")
        
        # Return empty string if template doesn't exist
        return "".html_safe unless File.exist?(template_path)
        
        # Use ActionView to render the template
        template = ActionView::Template.new(
          File.read(template_path),
          template_path,
          ActionView::Template.handler_for_extension("erb"),
          virtual_path: base_name
        )
        
        template.render(self, {}).html_safe
      end

      # Make call method public (ViewComponent::Base makes it private by default)
      public :call
    end
  end
end
