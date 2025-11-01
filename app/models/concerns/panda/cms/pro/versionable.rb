# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      module Versionable
        extend ActiveSupport::Concern

        included do
          has_many :content_versions, as: :versionable,
                   class_name: "Panda::CMS::Pro::ContentVersion",
                   dependent: :destroy

          has_many :content_suggestions, as: :suggestable,
                   class_name: "Panda::CMS::Pro::ContentSuggestion",
                   dependent: :destroy

          has_many :content_comments, as: :commentable,
                   class_name: "Panda::CMS::Pro::ContentComment",
                   dependent: :destroy

          after_save :create_version_on_content_change, if: :should_create_version?
        end

        def create_version!(user: nil, change_summary: nil, source: "manual")
          content_versions.create!(
            content: versionable_content,
            user: user,
            change_summary: change_summary || default_change_summary,
            source: source
          )
        end

        def latest_version
          content_versions.ordered.first
        end

        def version(number)
          content_versions.find_by(version_number: number)
        end

        def restore_version!(version_number, user: nil)
          version = self.version(version_number)
          return false unless version

          transaction do
            update_from_version_content(version.content)

            create_version!(
              user: user,
              change_summary: "Restored to version #{version_number}",
              source: "manual"
            )
          end
        end

        def contributors
          Panda::CMS::Pro::ContentVersion.contributors_for(self)
        end

        def contributors_count
          Panda::CMS::Pro::ContentVersion.contributor_count_for(self)
        end

        def pending_suggestions
          content_suggestions.for_review
        end

        def unresolved_comments
          content_comments.unresolved
        end

        def diff_with_version(version_number)
          version = self.version(version_number)
          return nil unless version

          {
            current_content: versionable_content,
            version_content: version.content,
            version_number: version_number,
            changes_since: content_versions.where("version_number > ?", version_number).count
          }
        end

        private

        def versionable_content
          if respond_to?(:content)
            content.is_a?(Hash) ? content : {data: content}
          else
            attributes.slice(*versionable_attributes)
          end
        end

        def versionable_attributes
          []
        end

        def update_from_version_content(version_content)
          if respond_to?(:content=)
            update(content: version_content)
          else
            update(version_content.slice(*versionable_attributes))
          end
        end

        def should_create_version?
          return false unless persisted?
          return false if content_versions.empty? && !saved_change_to_content?

          saved_change_to_content? || versionable_attributes_changed?
        end

        def versionable_attributes_changed?
          return false if versionable_attributes.empty?
          versionable_attributes.any? { |attr| saved_change_to_attribute?(attr) }
        end

        def default_change_summary
          if respond_to?(:title)
            "Updated #{title}"
          else
            "Content updated"
          end
        end

        def create_version_on_content_change
          return unless self.class.respond_to?(:auto_version_on_save?) && self.class.auto_version_on_save?

          create_version!(
            change_summary: "Auto-saved version",
            source: "manual"
          )
        end

        class_methods do
          def auto_version_on_save(enabled = true)
            @auto_version_on_save = enabled
          end

          def auto_version_on_save?
            @auto_version_on_save || false
          end
        end
      end
    end
  end
end
