# Monkey patch to fix ViewComponent block handling in ERB templates
# This ensures blocks are executed when passed to render, not just .new()
#
# ViewComponent lifecycle:
# 1. Component.new is called
# 2. render(component) or <%= render component %> is called
# 3. ViewComponent's #render_in is called with the view context and block
# 4. The block from step 2 is passed to #render_in, not to initialize
#
# This means blocks passed to <%= render Component.new do %> don't reach initialize.
# We need to capture them in render_in instead.

Rails.application.config.to_prepare do
  # Fix TableComponent block handling
  Panda::Core::Admin::TableComponent.class_eval do
    # Override to capture the block properly
    def render_in(view_context, &block)
      # Execute the block before rendering if it wasn't executed in initialize
      if block_given? && @columns.empty?
        yield self
      end
      super
    end
  end

  # Fix PanelComponent block handling
  Panda::Core::Admin::PanelComponent.class_eval do
    # Override to capture the block properly
    def render_in(view_context, &block)
      # Execute the block before rendering if it wasn't executed in initialize
      # PanelComponent uses @body_content to track if block was executed
      if block_given? && @body_content.nil? && !heading_slot?
        yield self
      end
      super
    end

    # Override body_slot to fall back to content when @body_content isn't set
    # This supports both DSL style (panel.body { }) and direct content in render block
    def body_slot
      return @body_content.call if @body_content.present?
      # Fall back to content from render block if body wasn't explicitly set
      content if content.present?
    end

    # Override body_slot? to check both @body_content and content
    def body_slot?
      @body_content.present? || content.present?
    end
  end
end
