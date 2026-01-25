# frozen_string_literal: true

module Panda
  module CMS
    # Represents an image attached to a CMS block
    # Supports single images, keyed images (for specific slots), and image galleries
    #
    # @example Single image for a block
    #   block_content.block_images.create!(alt_text: "Hero image", position: 0)
    #
    # @example Multiple images with keys
    #   block_content.block_images.create!(key: "stat_1", alt_text: "Stat 1", position: 0)
    #   block_content.block_images.create!(key: "stat_2", alt_text: "Stat 2", position: 1)
    #
    # @example Image gallery
    #   3.times do |i|
    #     block_content.block_images.create!(
    #       caption: "Gallery image #{i + 1}",
    #       alt_text: "Photo #{i + 1}",
    #       position: i
    #     )
    #   end
    class BlockImage < ApplicationRecord
      self.table_name = "panda_cms_block_images"

      belongs_to :block_content,
        class_name: "Panda::CMS::BlockContent",
        foreign_key: :panda_cms_block_content_id,
        touch: true

      # Active Storage attachment for the image file
      has_one_attached :file do |attachable|
        # General purpose variants
        attachable.variant :thumbnail, resize_to_limit: [200, 200]
        attachable.variant :medium, resize_to_limit: [800, 600]
        attachable.variant :large, resize_to_limit: [1920, 1080]

        # Social sharing
        attachable.variant :og_share, resize_to_limit: [1200, 630]

        # Common homepage variants
        attachable.variant :homepage_stat, resize_to_limit: [400, 400]
        attachable.variant :homepage_hero, resize_to_limit: [1920, 1080]
        attachable.variant :homepage_support, resize_to_limit: [800, 600]
      end

      # Validations
      validates :position,
        presence: true,
        numericality: {only_integer: true, greater_than_or_equal_to: 0}
      validates :key,
        uniqueness: {scope: :panda_cms_block_content_id},
        allow_nil: true

      # Ordering by position
      default_scope { order(position: :asc) }

      # Scopes
      scope :with_key, ->(key) { unscoped.where(key: key) }
      scope :in_order, -> { unscoped.order(position: :asc) }
    end
  end
end
