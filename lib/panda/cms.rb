# frozen_string_literal: true

require "panda/cms/version"
require "panda/cms/seo/character_counter"

module Panda
  module CMS
    # Store the engine's importmap separately from the app's
    mattr_accessor :importmap
  end
end

require "panda/cms/engine"
