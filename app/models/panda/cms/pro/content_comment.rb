# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentComment < ApplicationRecord
        self.table_name = "panda_cms_pro_content_comments"

        belongs_to :commentable, polymorphic: true
        belongs_to :user, class_name: "Panda::Core::User"
        belongs_to :parent, class_name: "Panda::CMS::Pro::ContentComment", optional: true
        belongs_to :resolved_by, class_name: "Panda::Core::User", optional: true
        has_many :replies, class_name: "Panda::CMS::Pro::ContentComment",
                 foreign_key: :parent_id, dependent: :destroy

        validates :commentable_type, presence: true
        validates :commentable_id, presence: true
        validates :user_id, presence: true
        validates :content, presence: true

        scope :top_level, -> { where(parent_id: nil) }
        scope :replies, -> { where.not(parent_id: nil) }
        scope :unresolved, -> { where(resolved: false) }
        scope :resolved_comments, -> { where(resolved: true) }
        scope :for_section, ->(section) { where(section_identifier: section) }
        scope :recent, -> { order(created_at: :desc) }
        scope :oldest_first, -> { order(created_at: :asc) }

        def resolve!(resolver)
          update(
            resolved: true,
            resolved_by: resolver,
            resolved_at: Time.current
          )
        end

        def unresolve!
          update(
            resolved: false,
            resolved_by: nil,
            resolved_at: nil
          )
        end

        def top_level?
          parent_id.nil?
        end

        def reply?
          parent_id.present?
        end

        def thread
          if top_level?
            [self] + replies.includes(:replies)
          else
            root_comment.thread
          end
        end

        def root_comment
          return self if top_level?
          parent.root_comment
        end

        def total_replies
          replies.count + replies.sum(&:total_replies)
        end

        def has_replies?
          replies.any?
        end
      end
    end
  end
end
