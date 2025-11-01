# frozen_string_literal: true

module Panda
  module CMS
    module Pro
      class ContentSyncLog < ApplicationRecord
        self.table_name = "panda_cms_pro_content_sync_logs"

        belongs_to :user, class_name: "Panda::Core::User"

        validates :sync_type, presence: true
        validates :status, presence: true
        validates :user_id, presence: true
        validates :items_synced, presence: true

        enum :sync_type, {
          push: "push",
          pull: "pull"
        }

        enum :status, {
          pending: "pending",
          in_progress: "in_progress",
          completed: "completed",
          failed: "failed",
          rolled_back: "rolled_back"
        }

        scope :recent, -> { order(created_at: :desc) }
        scope :successful, -> { where(status: :completed) }
        scope :failed_syncs, -> { where(status: :failed) }
        scope :for_user, ->(user) { where(user: user) }
        scope :pushes, -> { where(sync_type: :push) }
        scope :pulls, -> { where(sync_type: :pull) }

        before_create :set_started_at

        def start!
          update(
            status: :in_progress,
            started_at: Time.current
          )
        end

        def complete!(summary_data = {})
          update(
            status: :completed,
            completed_at: Time.current,
            summary: summary.merge(summary_data)
          )
        end

        def fail!(error)
          error_message = error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error.to_s

          update(
            status: :failed,
            completed_at: Time.current,
            error_log: error_message
          )
        end

        def rollback!
          return false unless completed?
          update(status: :rolled_back)
        end

        def duration
          return nil if started_at.blank?
          return Time.current - started_at if completed_at.blank?
          completed_at - started_at
        end

        def add_synced_item(item_type, item_id, action)
          self.items_synced = items_synced + [{
            type: item_type,
            id: item_id,
            action: action,
            synced_at: Time.current.iso8601
          }]
          save
        end

        def items_by_action
          items_synced.group_by { |item| item["action"] }
            .transform_values(&:count)
        end

        def items_by_type
          items_synced.group_by { |item| item["type"] }
            .transform_values(&:count)
        end

        def running?
          in_progress?
        end

        def succeeded?
          completed?
        end

        private

        def set_started_at
          self.started_at = Time.current if started_at.blank?
        end
      end
    end
  end
end
