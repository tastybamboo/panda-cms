require "rubygems"
require "panda/core"
require "panda/cms/railtie"

require "capybara/rspec"

module Panda
  module CMS
    extend Dry::Configurable

    setting :title, default: "Demo Site"
    setting :admin_path, default: "/admin"
    setting :require_login_to_view, default: false
    setting :authentication, default: {}
    setting :posts, default: {enabled: true, prefix: "blog"}
    setting :route_namespace, default: "/admin"
    setting :url
    setting :editor_js_tools, default: []
    setting :editor_js_tool_config, default: {}

    def self.root_path
      config.admin_path
    end

    class << self
      attr_accessor :loader

      def route_namespace
        config.admin_path
      end

      def configure
        yield config if block_given?
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
require_relative "panda/cms/exceptions_app"
require_relative "panda/cms/engine"
require_relative "panda/cms/demo_site_generator"
require_relative "panda/cms/editor_js"
require_relative "panda/cms/editor_js_content"
require_relative "panda/cms/editor_js/renderer"
require_relative "panda/cms/editor_js/blocks/alert"
require_relative "panda/cms/editor_js/blocks/header"
require_relative "panda/cms/editor_js/blocks/image"
require_relative "panda/cms/editor_js/blocks/list"
require_relative "panda/cms/editor_js/blocks/paragraph"
require_relative "panda/cms/editor_js/blocks/quote"
require_relative "panda/cms/editor_js/blocks/table"
require_relative "panda/cms/slug"

Panda::CMS.loader.setup
