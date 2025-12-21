# frozen_string_literal: true

module Panda
  module CMS
    class FormMailer < Panda::CMS::ApplicationMailer
      # Send notification to admin/site owners when a form is submitted
      #
      # @param form [Panda::CMS::Form] The form that was submitted
      # @param form_submission [Panda::CMS::FormSubmission] The submission data
      # @param recipients [Array<String>] Email addresses to send to
      def notification_email(form:, form_submission:, recipients: nil)
        @form = form
        @submission_data = form_submission.data
        @form_submission = form_submission
        @form_fields = form.form_fields.active.ordered

        # Use configured recipients or fall back to empty (caller should check)
        recipients ||= form.notification_email_list
        return if recipients.blank?

        # Extract sender info for reply-to if available
        email_field = @form_fields.find { |f| f.field_type == "email" }
        name_field = @form_fields.find { |f| f.name.include?("name") }

        @sender_email = email_field ? @submission_data[email_field.name] : @submission_data["email"]
        @sender_name = if name_field
          @submission_data[name_field.name]
        else
          "#{@submission_data["first_name"]} #{@submission_data["last_name"]}".strip
        end

        subject = form.notification_subject.presence ||
          "#{form.name}: #{form_submission.created_at.strftime("%d %b %Y %H:%M")}"

        # Process template variables in subject
        subject = process_template(subject, @submission_data)

        mail_options = {
          subject: subject,
          to: recipients,
          from: email_address_with_name(default_from_email, default_from_name)
        }

        if @sender_email.present?
          mail_options[:reply_to] = email_address_with_name(@sender_email, @sender_name.presence || @sender_email)
        end

        mail(mail_options)
      end

      # Send confirmation email to the form submitter
      #
      # @param form [Panda::CMS::Form] The form that was submitted
      # @param form_submission [Panda::CMS::FormSubmission] The submission data
      # @param recipient [String] Email address of the submitter
      def confirmation_email(form:, form_submission:, recipient:)
        @form = form
        @submission_data = form_submission.data
        @form_submission = form_submission

        return if recipient.blank?

        # Process confirmation body template
        @body_content = process_template(form.confirmation_body.to_s, @submission_data)

        subject = form.confirmation_subject.presence || "Thank you for your submission"
        subject = process_template(subject, @submission_data)

        mail(
          subject: subject,
          to: recipient,
          from: email_address_with_name(default_from_email, default_from_name)
        )
      end

      private

      # Replace {{field_name}} placeholders with actual values
      # @param template [String] Template text with placeholders
      # @param data [Hash] Submission data
      # @return [String] Processed text
      def process_template(template, data)
        return "" if template.blank?

        template.gsub(/\{\{(\w+)\}\}/) do |match|
          field_name = ::Regexp.last_match(1)
          value = data[field_name]
          value.is_a?(Array) ? value.join(", ") : value.to_s
        end
      end

      def default_from_email
        Panda::CMS.config.respond_to?(:mail_from) && Panda::CMS.config.mail_from.presence ||
          "noreply@#{default_host}"
      end

      def default_from_name
        Panda::CMS.config.respond_to?(:title) && Panda::CMS.config.title.presence ||
          "Panda CMS"
      end

      def default_host
        ActionMailer::Base.default_url_options[:host] || "localhost"
      end
    end
  end
end
