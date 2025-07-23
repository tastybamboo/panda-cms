# frozen_string_literal: true

module Panda
  module CMS
    class Form < ApplicationRecord
      self.table_name = "panda_cms_forms"

      has_many :form_submissions, class_name: "Panda::CMS::FormSubmission"
    end
  end
end
