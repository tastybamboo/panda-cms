# frozen_string_literal: true

module Panda
  module CMS
    # Base class for all ViewComponent components in Panda CMS
    # Inherits from ViewComponent::Base for all CMS components
    class Base < ::ViewComponent::Base
      # ViewComponent automatically renders .html.erb templates
      # No need to override call() - ViewComponent handles template finding
    end
  end
end
