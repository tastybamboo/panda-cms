# frozen_string_literal: true

module Panda
  module CMS
    module Debug
      class << self
        # Check if debug mode is enabled via PANDA_DEBUG environment variable
        def enabled?
          ENV["PANDA_DEBUG"].to_s.downcase == "true" || ENV["PANDA_DEBUG"] == "1"
        end

        # Log a debug message if debug mode is enabled
        def log(message)
          Panda::Core::Debug.log(message, prefix: "PANDA CMS")
        end

        # Log an object with pretty printing (using awesome_print if available)
        def inspect(object, label: nil)
          Panda::Core::Debug.inspect(object, label: label, prefix: "PANDA CMS")
        end

        # Enable HTTP debugging for Net::HTTP requests (delegates to Core)
        def enable_http_debug!
          Panda::Core::Debug.enable_http_debug!
        end
      end
    end
  end
end
