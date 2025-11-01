# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentVersion < ApplicationRecord
        self.table_name = "panda_cms_pro_content_versions"

        belongs_to :versionable, polymorphic: true
        belongs_to :user, class_name: "Panda::Core::User", optional: true
        has_many :content_changes, class_name: "Panda::CMS::Pro::ContentChange",
                 foreign_key: :panda_cms_pro_content_version_id, dependent: :destroy

        validates :versionable_type, presence: true
        validates :versionable_id, presence: true
        validates :version_number, presence: true, numericality: {greater_than: 0}
        validates :content, presence: true
        validates :source, presence: true, inclusion: {in: %w[manual ai_generated suggestion_approved]}

        before_validation :set_version_number, on: :create
        after_create :update_contributor_count

        scope :ordered, -> { order(version_number: :desc) }
        scope :recent, -> { ordered.limit(10) }
        scope :by_user, ->(user) { where(user: user) }
        scope :manual, -> { where(source: "manual") }
        scope :ai_generated, -> { where(source: "ai_generated") }
        scope :from_suggestions, -> { where(source: "suggestion_approved") }

        def previous_version
          self.class.where(
            versionable_type: versionable_type,
            versionable_id: versionable_id
          ).where("version_number < ?", version_number)
            .order(version_number: :desc)
            .first
        end

        def next_version
          self.class.where(
            versionable_type: versionable_type,
            versionable_id: versionable_id
          ).where("version_number > ?", version_number)
            .order(version_number: :asc)
            .first
        end

        def self.contributors_for(versionable)
          where(versionable: versionable)
            .where.not(user_id: nil)
            .select(:user_id)
            .distinct
            .map(&:user)
        end

        def self.contributor_count_for(versionable)
          where(versionable: versionable)
            .where.not(user_id: nil)
            .select(:user_id)
            .distinct
            .count
        end

        def diff(other_version)
          {
            from_version: other_version.version_number,
            to_version: version_number,
            from_content: other_version.content,
            to_content: content,
            changes: content_changes.count,
            user: user&.email,
            created_at: created_at
          }
        end

        def ai_generated?
          source == "ai_generated"
        end

        def from_suggestion?
          source == "suggestion_approved"
        end

        def manual?
          source == "manual"
        end

        private

        def set_version_number
          return if version_number.present?

          last_version = self.class.where(
            versionable_type: versionable_type,
            versionable_id: versionable_id
          ).maximum(:version_number)

          self.version_number = (last_version || 0) + 1
        end

        def update_contributor_count
          return unless versionable.respond_to?(:contributor_count)
          return if user_id.blank?

          count = self.class.contributor_count_for(versionable)
          versionable.update_column(:contributor_count, count)
          versionable.update_column(:last_contributed_at, created_at)
        end
      end
    end
  end
end
