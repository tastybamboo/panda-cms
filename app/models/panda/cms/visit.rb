# frozen_string_literal: true

module Panda
  module CMS
    class Visit < ApplicationRecord
      belongs_to :page, class_name: "Panda::CMS::Page", foreign_key: :panda_cms_page_id, optional: true
      belongs_to :user, class_name: "Panda::CMS::User", foreign_key: :user_id, optional: true
      belongs_to :redirect, class_name: "Panda::CMS::Redirect", foreign_key: :redirect_id, optional: true
    end
  end
end
