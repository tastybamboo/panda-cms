# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentSuggestion < ApplicationRecord
        self.table_name = "panda_cms_pro_content_suggestions"

        belongs_to :suggestable, polymorphic: true
        belongs_to :user, class_name: "Panda::Core::User"
        belongs_to :reviewed_by, class_name: "Panda::Core::User", optional: true

        validates :suggestable_type, presence: true
        validates :suggestable_id, presence: true
        validates :user_id, presence: true
        validates :suggestion_type, presence: true
        validates :status, presence: true
        validates :content, presence: true

        enum :suggestion_type, {
          edit: "edit",
          addition: "addition",
          deletion: "deletion",
          comment: "comment",
          citation: "citation"
        }

        enum :status, {
          pending: "pending",
          specialist_review: "specialist_review",
          admin_review: "admin_review",
          approved: "approved",
          rejected: "rejected"
        }

        scope :for_review, -> { where(status: [:pending, :specialist_review, :admin_review]) }
        scope :needs_specialist, -> { where(requires_specialist_review: true) }
        scope :recent, -> { order(created_at: :desc) }
        scope :by_status, ->(status) { where(status: status) }
        scope :by_user, ->(user) { where(user: user) }

        after_update :notify_user_of_decision, if: :saved_change_to_status?

        def approve!(reviewer, notes: nil)
          transaction do
            update!(
              status: :approved,
              reviewed_by: reviewer,
              reviewed_at: Time.current,
              admin_notes: notes
            )

            Panda::CMS::Pro::ContentVersion.create!(
              versionable: suggestable,
              content: apply_suggestion_to_content,
              change_summary: "Applied suggestion: #{rationale || content.truncate(50)}",
              user: user,
              source: "suggestion_approved"
            )
          end
        end

        def reject!(reviewer, notes:)
          update(
            status: :rejected,
            reviewed_by: reviewer,
            reviewed_at: Time.current,
            admin_notes: notes
          )
        end

        def send_to_specialist_review!
          update(
            status: :specialist_review,
            requires_specialist_review: true
          )
        end

        def send_to_admin_review!
          update(status: :admin_review)
        end

        def pending_review?
          pending? || specialist_review? || admin_review?
        end

        def reviewed?
          approved? || rejected?
        end

        def sources
          metadata["sources"] || []
        end

        def add_source(source_url)
          self.metadata = metadata.merge(
            "sources" => (sources + [source_url]).uniq
          )
          save
        end

        private

        def apply_suggestion_to_content
          current_content = suggestable.try(:content) || {}

          case suggestion_type
          when "edit", "addition"
            current_content.deep_merge(suggested_changes)
          when "deletion"
            current_content
          else
            current_content
          end
        end

        def suggested_changes
          begin
            JSON.parse(content)
          rescue JSON::ParserError
            {"raw_content" => content}
          end
        end

        def notify_user_of_decision
          # Hook for notification system
        end
      end
    end
  end
end
