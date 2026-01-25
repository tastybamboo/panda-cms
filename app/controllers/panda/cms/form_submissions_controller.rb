# frozen_string_literal: true

module Panda
  module CMS
    class FormSubmissionsController < ApplicationController
      # Spam protection - invisible honeypot field
      # Use custom callbacks to avoid calling root_path (not available in engine context)
      # Note: timestamp validation is disabled (see initializer) - we use custom timing checks instead
      # Disabled in test environment to avoid interference with test suite
      invisible_captcha only: [:create],
        on_spam: :handle_invisible_captcha_spam unless Rails.env.test?

      # Rate limiting to prevent spam
      before_action :check_rate_limit, only: [:create]

      def create
        form = Panda::CMS::Form.find(params[:id])

        # Check if form is accepting submissions
        unless form.accepting_submissions?
          redirect_to_fallback(form, error: true, message: "This form is not currently accepting submissions.")
          return
        end

        # Additional spam checks
        if looks_like_spam?(params)
          log_spam_attempt(form, "content")
          redirect_to_fallback(form, spam: true)
          return
        end

        # Timing-based spam detection (honeypot timing)
        if submitted_too_quickly?(params)
          log_spam_attempt(form, "timing")
          redirect_to_fallback(form, spam: true)
          return
        end

        # Build submission data from allowed fields
        submission_data = build_submission_data(form, params)

        # Create submission
        form_submission = Panda::CMS::FormSubmission.new(
          form: form,
          data: submission_data,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )

        # Handle file uploads
        handle_file_uploads(form, form_submission, params)

        # Validate and save
        unless form_submission.valid?
          redirect_to_fallback(form, error: true, message: form_submission.errors.full_messages.to_sentence)
          return
        end

        form_submission.save!

        # Note: submission_count is auto-incremented via counter_cache on the belongs_to association

        # Send notification emails
        send_notification_emails(form, form_submission)

        # Redirect with custom success message if configured
        success_message = form.success_message.presence || "Thank you for your submission!"
        redirect_to_fallback(form, success: true, message: success_message)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger&.error "Form submission validation failed: #{e.message}"
        redirect_to_fallback(form, error: true, message: e.record.errors.full_messages.to_sentence)
      end

      private

      # Build submission data from allowed form fields
      # If form has field definitions, only allow those fields
      # Otherwise, allow all params except system params
      def build_submission_data(form, params)
        system_params = %i[authenticity_token controller action id _form_timestamp spinner]

        if form.form_fields.any?
          # Only accept defined field names (excluding file fields which are handled separately)
          allowed_fields = form.form_fields.active.where.not(field_type: "file").pluck(:name)
          params.to_unsafe_h.slice(*allowed_fields)
        else
          # Legacy behavior - accept all params except system params
          params.except(*system_params).to_unsafe_h
        end
      end

      # Handle file uploads and attach to submission
      def handle_file_uploads(form, submission, params)
        return unless form.form_fields.any?

        form.form_fields.where(field_type: "file", active: true).each do |field|
          uploaded_file = params[field.name]
          next unless uploaded_file.present? && uploaded_file.respond_to?(:read)

          submission.files.attach(uploaded_file)

          # Store metadata for reference
          submission.files_metadata ||= {}
          submission.files_metadata[field.name] = {
            "filename" => uploaded_file.original_filename,
            "content_type" => uploaded_file.content_type,
            "size" => uploaded_file.size
          }
        end
      end

      # Send notification emails
      def send_notification_emails(form, form_submission)
        # Send admin notification if configured
        recipients = form.notification_email_list
        if recipients.any?
          begin
            Panda::CMS::FormMailer.notification_email(
              form: form,
              form_submission: form_submission,
              recipients: recipients
            ).deliver_later
          rescue => e
            Rails.logger&.error "Failed to send form notification email: #{e.message}"
          end
        end

        # Send confirmation to submitter if configured
        if form.send_confirmation && form.confirmation_email_field.present?
          submitter_email = form_submission.data[form.confirmation_email_field]
          if submitter_email.present?
            begin
              Panda::CMS::FormMailer.confirmation_email(
                form: form,
                form_submission: form_submission,
                recipient: submitter_email
              ).deliver_later
            rescue => e
              Rails.logger&.error "Failed to send form confirmation email: #{e.message}"
            end
          end
        end
      end

      # Check for basic spam indicators
      def looks_like_spam?(params)
        # Check for too many URLs in message fields
        message_fields = params.values.select { |v| v.is_a?(String) && v.length > 20 }
        message_fields.any? { |field| field.scan(/https?:\/\//).length > 3 }
      end

      # Timing-based spam detection
      # Rejects submissions that are too fast (< 3 seconds) or too stale (> 24 hours)
      def submitted_too_quickly?(params)
        return false unless params[:_form_timestamp].present?

        begin
          form_loaded_at = Time.zone.at(params[:_form_timestamp].to_i)
          time_elapsed = Time.current - form_loaded_at

          # Too fast - likely a bot (< 3 seconds)
          if time_elapsed < 3.seconds
            Rails.logger&.warn "Form submitted too quickly: #{time_elapsed.round(2)}s from IP: #{request.remote_ip}"
            return true
          end

          # Too stale - form held too long without interaction (> 24 hours)
          if time_elapsed > 24.hours
            Rails.logger&.warn "Form submission too old: #{(time_elapsed / 1.hour).round(1)}h from IP: #{request.remote_ip}"
            return true
          end

          false
        rescue ArgumentError, TypeError => e
          Rails.logger&.warn "Invalid form timestamp from IP #{request.remote_ip}: #{e.message}"
          # Don't reject on invalid timestamp - might be legitimate user with modified form
          false
        end
      end

      # Rate limiting - max 3 submissions per IP per 5 minutes
      def check_rate_limit
        cache_key = "form_submission_rate_limit:#{request.remote_ip}"
        count = Rails.cache.read(cache_key) || 0

        if count >= 3
          Rails.logger&.warn "Rate limit exceeded for IP: #{request.remote_ip}"
          render plain: "Too many requests. Please try again later.", status: :too_many_requests
          return
        end

        Rails.cache.write(cache_key, count + 1, expires_in: 5.minutes)
      end

      # Log spam attempt with reason
      def log_spam_attempt(form, reason)
        Rails.logger&.warn "Spam detected (#{reason}) for form #{form.id} from IP: #{request.remote_ip}"
      end

      # Callback for invisible_captcha spam detection (honeypot and timestamp)
      # Must redirect using fallback "/" since root_path is not available in engine context
      def handle_invisible_captcha_spam
        Rails.logger&.warn "Invisible captcha triggered from IP: #{request.remote_ip}"
        redirect_back(fallback_location: "/", allow_other_host: false)
      end

      # Safe redirect that works in engine context
      def redirect_to_fallback(form, success: false, spam: false, error: false, message: nil)
        fallback = "/"

        if spam
          # Redirect to same page to appear successful (don't tell spammers)
          redirect_back(fallback_location: fallback, allow_other_host: false)
        elsif success && form.completion_path.present?
          # Redirect to custom completion path
          redirect_to form.completion_path, notice: message || "Thank you for your submission!"
        elsif success
          # Redirect back to referring page with success message
          redirect_back(
            fallback_location: fallback,
            notice: message || "Thank you for your submission!",
            allow_other_host: false
          )
        elsif error
          # Redirect back with error message
          redirect_back(
            fallback_location: fallback,
            alert: message || "There was an error submitting your form. Please try again.",
            allow_other_host: false
          )
        else
          # Default fallback
          redirect_back(fallback_location: fallback, allow_other_host: false)
        end
      end
    end
  end
end
