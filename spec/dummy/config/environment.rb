# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

# Unfreeze arrays before Rails initialization
if defined?(ActiveSupport::Dependencies)
  if ActiveSupport::Dependencies.autoload_paths.frozen?
    ActiveSupport::Dependencies.autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup
  end
  if ActiveSupport::Dependencies.autoload_once_paths.frozen?
    ActiveSupport::Dependencies.autoload_once_paths = ActiveSupport::Dependencies.autoload_once_paths.dup
  end
end

# Initialize the Rails application.
Rails.application.initialize!
