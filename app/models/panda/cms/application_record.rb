# frozen_string_literal: true

module Panda
  module CMS
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
      self.implicit_order_column = "created_at"
    end
  end
end
