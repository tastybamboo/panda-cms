# frozen_string_literal: true

module Panda
  module CMS
    class FormSubmission < ApplicationRecord
      self.table_name = "panda_cms_form_submissions"

      belongs_to :form, class_name: "Panda::CMS::Form"

      has_many_attached :files

      validates :data, presence: true

      validate :validate_required_fields, if: -> { form&.form_fields&.any? }
      validate :validate_field_formats, if: -> { form&.form_fields&.any? }

      private

      # Validate that all required fields are present in submission data
      def validate_required_fields
        form.form_fields.where(required: true, active: true).each do |field|
          if data[field.name].blank?
            errors.add(:base, "#{field.label} is required")
          end
        end
      end

      # Validate field-specific formats (email, phone)
      def validate_field_formats
        form.form_fields.active.each do |field|
          value = data[field.name]
          next if value.blank?

          case field.field_type
          when "email"
            unless value.match?(URI::MailTo::EMAIL_REGEXP)
              errors.add(:base, "#{field.label} must be a valid email address")
            end
          when "phone"
            unless value.match?(/\A[\d\s\-+()]+\z/)
              errors.add(:base, "#{field.label} must be a valid phone number")
            end
          when "url"
            unless value.match?(%r{\Ahttps?://[^\s]+\z}i)
              errors.add(:base, "#{field.label} must be a valid URL (starting with http:// or https://)")
            end
          end
        end
      end
    end
  end
end
