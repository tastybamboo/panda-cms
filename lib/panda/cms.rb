# frozen_string_literal: true

require "panda/cms/engine"

module Panda
  module CMS
    # Store the engine's importmap separately from the app's
    mattr_accessor :importmap
  end
end
