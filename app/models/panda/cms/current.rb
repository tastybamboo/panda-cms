# frozen_string_literal: true

module Panda
  module CMS
    class Current < Panda::Core::Current
      # CMS-specific attributes
      attribute :page
    end
  end
end
