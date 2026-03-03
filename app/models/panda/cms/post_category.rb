# frozen_string_literal: true

module Panda
  module CMS
    class PostCategory < ApplicationRecord
      self.table_name = "panda_cms_post_categories"

      has_many :posts, class_name: "Panda::CMS::Post", foreign_key: :post_category_id, dependent: :restrict_with_error

      validates :name, presence: true, uniqueness: true
      validates :slug, presence: true, uniqueness: true,
        format: {with: /\A[a-z0-9-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens"}

      before_validation :generate_slug

      scope :ordered, -> { order(:name) }

      def deletable?
        slug != "general"
      end

      private

      def generate_slug
        return if name.blank?

        self.slug = name.parameterize if slug.blank?
      end
    end
  end
end
