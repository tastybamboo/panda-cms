# frozen_string_literal: true

module Panda
  module CMS
    module Admin
      # Base controller for all CMS admin controllers
      # Inherits from Core AdminController for authentication
      # Adds CMS-specific helpers and functionality
      class BaseController < ::Panda::Core::AdminController
        # Include CMS helpers so views have access to panda_cms_form_with, etc.
        helper Panda::CMS::ApplicationHelper
        
        # Include the helper methods in the controller as well
        include Panda::CMS::ApplicationHelper
      end
    end
  end
end