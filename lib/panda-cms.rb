# frozen_string_literal: true

require "rubygems"
require "panda/core"
require "panda/cms/railtie"

module Panda
  module CMS
    class Configuration
      attr_accessor :title, :require_login_to_view, :authentication,
        :posts, :url, :instagram, :analytics

      def initialize
        @title = "Demo Site"
        @require_login_to_view = false
        @authentication = {}
        @posts = {enabled: true, prefix: "blog"}
        @url = nil
        @instagram = {
          enabled: false,
          username: nil,
          access_token: nil
        }
        @analytics = {
          google_analytics: {
            enabled: false,
            tracking_id: nil
          }
        }
      end
    end

    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def config
        configuration
      end

      def configure
        yield configuration if block_given?
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end

    def self.root_path
      # Delegate to Panda::Core's admin_path configuration
      Panda::Core.config.admin_path
    end

    class << self
      attr_accessor :loader

      def route_namespace
        # Delegate to Panda::Core's admin_path configuration
        Panda::Core.config.admin_path
      end
    end
  end
end

# Set up autoloading for the gem's internals
Panda::CMS.loader = Zeitwerk::Loader.new
Panda::CMS.loader.tag = "panda-cms"

# Ignore the panda-cms directory
Panda::CMS.loader.ignore("#{__dir__}/panda-cms")

# Only autoload the panda/cms directory
Panda::CMS.loader.push_dir(File.expand_path("panda/cms", __dir__), namespace: Panda::CMS)

# Ignore both lib and lib/panda directories to prevent Rails autoloader conflicts
Panda::CMS.loader.ignore(__dir__.to_s)
Panda::CMS.loader.ignore(File.expand_path("panda", __dir__))

# Configure Zeitwerk inflections
Panda::CMS.loader.inflector.inflect(
  "cms" => "CMS"
)

# Manually require files from panda-cms directory
require_relative "panda-cms/version"
require_relative "panda/cms/debug"
require_relative "panda/cms/exceptions_app"
require_relative "panda/cms/engine"
require_relative "panda/cms/demo_site_generator"
require_relative "panda/cms/asset_loader"
require_relative "panda/cms/features"
require_relative "panda/cms/slug"

Panda::CMS.loader.setup
