# frozen_string_literal: true

module Panda
  module CMS
    class FormSubmissionsController < ApplicationController
      # Spam protection - invisible honeypot field
      invisible_captcha only: [:create], on_spam: :log_spam

      # Rate limiting to prevent spam
      before_action :check_rate_limit, only: [:create]

      def create
        form = Panda::CMS::Form.find(params[:id])

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

        # Clean parameters - exclude system params and honeypot field
        vars = params.except(:authenticity_token, :controller, :action, :id, :_form_timestamp, :spinner)

        # Create submission
        form_submission = Panda::CMS::FormSubmission.create!(
          form_id: form.id,
          data: vars.to_unsafe_h,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )

        # Update submission count
        form.increment!(:submission_count)

        # Send notification email (in background if possible)
        begin
          Panda::CMS::FormMailer.notification_email(form: form, form_submission: form_submission).deliver_now
        rescue => e
          Rails.logger.error "Failed to send form notification email: #{e.message}"
          # Don't fail the submission if email fails
        end

        redirect_to_fallback(form, success: true)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Form submission validation failed: #{e.message}"
        redirect_to_fallback(form, error: true)
      end

      private

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
            Rails.logger.warn "Form submitted too quickly: #{time_elapsed.round(2)}s from IP: #{request.remote_ip}"
            return true
          end

          # Too stale - form held too long without interaction (> 24 hours)
          if time_elapsed > 24.hours
            Rails.logger.warn "Form submission too old: #{(time_elapsed / 1.hour).round(1)}h from IP: #{request.remote_ip}"
            return true
          end

          false
        rescue ArgumentError, TypeError => e
          Rails.logger.warn "Invalid form timestamp from IP #{request.remote_ip}: #{e.message}"
          # Don't reject on invalid timestamp - might be legitimate user with modified form
          false
        end
      end

      # Rate limiting - max 3 submissions per IP per 5 minutes
      def check_rate_limit
        cache_key = "form_submission_rate_limit:#{request.remote_ip}"
        count = Rails.cache.read(cache_key) || 0

        if count >= 3
          Rails.logger.warn "Rate limit exceeded for IP: #{request.remote_ip}"
          render plain: "Too many requests. Please try again later.", status: :too_many_requests
          return
        end

        Rails.cache.write(cache_key, count + 1, expires_in: 5.minutes)
      end

      # Log spam attempt with reason
      def log_spam_attempt(form, reason)
        Rails.logger.warn "Spam detected (#{reason}) for form #{form.id} from IP: #{request.remote_ip}"
      end

      # Callback for invisible_captcha spam detection
      def log_spam
        Rails.logger.warn "Invisible captcha triggered from IP: #{request.remote_ip}"
      end

      # Safe redirect that works in engine context
      def redirect_to_fallback(form, success: false, spam: false, error: false)
        if spam
          # Redirect to same page to appear successful (don't tell spammers)
          redirect_back(fallback_location: main_app.root_path, allow_other_host: false)
        elsif success && form.completion_path.present?
          # Redirect to custom completion path
          redirect_to form.completion_path, notice: "Thank you for your submission!"
        elsif success
          # Redirect back to referring page with success message
          redirect_back(
            fallback_location: main_app.root_path,
            notice: "Thank you for your submission!",
            allow_other_host: false
          )
        elsif error
          # Redirect back with error message
          redirect_back(
            fallback_location: main_app.root_path,
            alert: "There was an error submitting your form. Please try again.",
            allow_other_host: false
          )
        else
          # Default fallback
          redirect_back(fallback_location: main_app.root_path, allow_other_host: false)
        end
      end
    end
  end
end
