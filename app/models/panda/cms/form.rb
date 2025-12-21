# frozen_string_literal: true

module Panda
  module CMS
    class Form < ApplicationRecord
      self.table_name = "panda_cms_forms"

      has_many :form_fields, -> { order(:position) },
        class_name: "Panda::CMS::FormField",
        dependent: :destroy
      has_many :form_submissions,
        class_name: "Panda::CMS::FormSubmission",
        dependent: :destroy

      accepts_nested_attributes_for :form_fields, allow_destroy: true, reject_if: :all_blank

      validates :name, presence: true, uniqueness: true
      validates :status, inclusion: {in: %w[active draft archived]}, allow_nil: true

      scope :published, -> { where(status: "active") }

      # Parse notification_emails as JSON array
      # @return [Array<String>] List of email addresses
      def notification_email_list
        return [] if notification_emails.blank?
        JSON.parse(notification_emails)
      rescue JSON::ParserError
        # Handle comma-separated fallback for manual entry
        notification_emails.split(",").map(&:strip).reject(&:blank?)
      end

      # Set notification emails from array or comma-separated string
      # @param emails [Array<String>, String] Email addresses
      def notification_email_list=(emails)
        self.notification_emails = if emails.is_a?(Array)
          emails.reject(&:blank?).to_json
        else
          emails
        end
      end

      # Get the field that should receive the submitter's email for confirmation
      # @return [Panda::CMS::FormField, nil]
      def email_field_for_confirmation
        return nil unless send_confirmation && confirmation_email_field.present?
        form_fields.find_by(name: confirmation_email_field)
      end

      # Check if form is currently accepting submissions
      # @return [Boolean]
      def accepting_submissions?
        status.nil? || status == "active"
      end
    end
  end
end
