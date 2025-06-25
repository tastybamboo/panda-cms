# frozen_string_literal: true

module Panda
  module Social
    class InstagramPost < ApplicationRecord
      self.table_name = "panda_social_instagram_posts"

      has_one_attached :image

      validates :instagram_id, presence: true, uniqueness: true
      validates :caption, presence: true
      validates :posted_at, presence: true

      scope :ordered, -> { order(posted_at: :desc) }
    end
  end
end
