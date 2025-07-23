# frozen_string_literal: true

module Panda
  module CMS
    class Redirect < ApplicationRecord
      belongs_to :origin_page, class_name: "Panda::CMS::Page", foreign_key: :origin_panda_cms_page_id, optional: true
      belongs_to :destination_page, class_name: "Panda::CMS::Page", foreign_key: :destination_panda_cms_page_id,
        optional: true

      validates :status_code, presence: true
      validates :visits, presence: true
      validates :origin_path, presence: true
      validates :destination_path, presence: true

      validates :origin_path, format: {with: %r{\A/.*\z}, message: "must start with a forward slash"}
      validates :destination_path, format: {with: %r{\A/.*\z}, message: "must start with a forward slash"}
    end
  end
end
