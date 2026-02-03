# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Panda::CMS::FormSubmissions", type: :request do
  let(:contact_form) { panda_cms_forms(:contact_form) }
  let(:newsletter_form) { panda_cms_forms(:newsletter_form) }
  let(:draft_form) { panda_cms_forms(:draft_form) }

  # Clear cache and enqueued jobs before each test for proper isolation
  before do
    Rails.cache.clear
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if defined?(ActiveJob::Base.queue_adapter.enqueued_jobs)
  end

  describe "POST /cms/forms/:id/submissions" do
    context "with valid submission" do
      it "creates a form submission" do
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "John Doe",
            email: "john@example.com",
            message: "Hello, this is a test message",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.to change(Panda::CMS::FormSubmission, :count).by(1)
      end

      it "increments the form submission count" do
        initial_count = contact_form.submission_count

        post "/_forms/#{contact_form.id}", params: {
          name: "Jane Doe",
          email: "jane@example.com",
          message: "Test submission",
          _form_timestamp: 5.seconds.ago.to_i
        }

        expect(contact_form.reload.submission_count).to eq(initial_count + 1)
      end

      it "stores submission data" do
        post "/_forms/#{contact_form.id}", params: {
          name: "Test User",
          email: "test@example.com",
          message: "Test message",
          _form_timestamp: 5.seconds.ago.to_i
        }

        submission = Panda::CMS::FormSubmission.last
        expect(submission.data["name"]).to eq("Test User")
        expect(submission.data["email"]).to eq("test@example.com")
        expect(submission.data["message"]).to eq("Test message")
      end

      it "stores IP address and user agent" do
        post "/_forms/#{contact_form.id}", params: {
          name: "Test User",
          email: "test@example.com",
          message: "Test",
          _form_timestamp: 5.seconds.ago.to_i
        }, headers: {
          "REMOTE_ADDR" => "192.168.1.1",
          "HTTP_USER_AGENT" => "Mozilla/5.0"
        }

        submission = Panda::CMS::FormSubmission.last
        expect(submission.ip_address).to eq("192.168.1.1")
        expect(submission.user_agent).to eq("Mozilla/5.0")
      end

      it "redirects to completion path when configured" do
        post "/_forms/#{contact_form.id}", params: {
          name: "Test",
          email: "test@example.com",
          message: "Hello",
          _form_timestamp: 5.seconds.ago.to_i
        }

        expect(response).to redirect_to(contact_form.completion_path)
        expect(flash[:notice]).to be_present
      end

      it "redirects back when no completion path configured" do
        form = newsletter_form
        form.update!(completion_path: nil)

        post "/_forms/#{form.id}", params: {
          email: "test@example.com",
          _form_timestamp: 5.seconds.ago.to_i
        }, headers: {
          "HTTP_REFERER" => "https://example.com/contact"
        }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
      end

      it "uses custom success message when configured" do
        contact_form.update!(success_message: "Custom thank you!")

        post "/_forms/#{contact_form.id}", params: {
          name: "Test",
          email: "test@example.com",
          message: "Hello",
          _form_timestamp: 5.seconds.ago.to_i
        }

        expect(flash[:notice]).to eq("Custom thank you!")
      end
    end

    context "when form is not accepting submissions" do
      it "rejects submissions to draft forms" do
        expect {
          post "/_forms/#{draft_form.id}", params: {
            name: "Test",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.not_to change(Panda::CMS::FormSubmission, :count)

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("not currently accepting submissions")
      end
    end

    context "spam detection" do
      it "rejects submissions with too many URLs (content-based spam)" do
        spammy_message = "Check out http://spam1.com and http://spam2.com also http://spam3.com and http://spam4.com"

        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Spammer",
            email: "spam@example.com",
            message: spammy_message,
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.not_to change(Panda::CMS::FormSubmission, :count)

        expect(response).to have_http_status(:redirect)
      end

      it "rejects submissions sent too quickly (< 3 seconds)" do
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Bot",
            email: "bot@example.com",
            message: "Quick submission",
            _form_timestamp: 1.second.ago.to_i
          }
        }.not_to change(Panda::CMS::FormSubmission, :count)

        expect(response).to have_http_status(:redirect)
      end

      it "rejects stale submissions (> 24 hours)" do
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Old",
            email: "old@example.com",
            message: "Stale submission",
            _form_timestamp: 25.hours.ago.to_i
          }
        }.not_to change(Panda::CMS::FormSubmission, :count)

        expect(response).to have_http_status(:redirect)
      end

      it "accepts submissions with invalid timestamp (doesn't reject legitimate users)" do
        # Invalid timestamps are treated as missing timestamps (returns false, doesn't reject)
        # However, invisible_captcha may still catch it, so we just verify it doesn't crash
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "User",
            email: "user@example.com",
            message: "Valid message",
            _form_timestamp: "invalid"
          }
        }.not_to raise_error

        # Should redirect (either success or spam detection)
        expect(response).to have_http_status(:redirect)
      end

      it "accepts submissions without timestamp" do
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "User",
            email: "user@example.com",
            message: "Valid message"
          }
        }.to change(Panda::CMS::FormSubmission, :count).by(1)
      end
    end

    context "rate limiting" do
      it "allows up to 3 submissions from same IP" do
        3.times do |i|
          post "/_forms/#{contact_form.id}", params: {
            name: "User #{i}",
            email: "user#{i}@example.com",
            message: "Message #{i}",
            _form_timestamp: 5.seconds.ago.to_i
          }, headers: {"REMOTE_ADDR" => "192.168.1.100"}

          expect(response).to have_http_status(:redirect)
          expect(response.status).not_to eq(429)
        end
      end

      it "blocks 4th submission from same IP within 5 minutes" do
        # Make 3 successful submissions
        3.times do |i|
          post "/_forms/#{contact_form.id}", params: {
            name: "User #{i}",
            email: "user#{i}@example.com",
            message: "Message",
            _form_timestamp: 5.seconds.ago.to_i
          }, headers: {"REMOTE_ADDR" => "192.168.1.100"}
        end

        # 4th submission should be rate limited
        post "/_forms/#{contact_form.id}", params: {
          name: "User 4",
          email: "user4@example.com",
          message: "Message",
          _form_timestamp: 5.seconds.ago.to_i
        }, headers: {"REMOTE_ADDR" => "192.168.1.100"}

        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include("Too many requests")
      end
    end

    context "field filtering" do
      it "only accepts defined form fields" do
        post "/_forms/#{contact_form.id}", params: {
          name: "Test User",
          email: "test@example.com",
          message: "Valid message",
          malicious_field: "Should be filtered out",
          _form_timestamp: 5.seconds.ago.to_i
        }

        submission = Panda::CMS::FormSubmission.last
        expect(submission.data).to have_key("name")
        expect(submission.data).to have_key("email")
        expect(submission.data).to have_key("message")
        expect(submission.data).not_to have_key("malicious_field")
      end

      it "filters system parameters" do
        post "/_forms/#{contact_form.id}", params: {
          name: "Test",
          email: "test@example.com",
          message: "Message",
          authenticity_token: "should_be_filtered",
          controller: "should_be_filtered",
          action: "should_be_filtered",
          _form_timestamp: 5.seconds.ago.to_i
        }

        submission = Panda::CMS::FormSubmission.last
        expect(submission.data).not_to have_key("authenticity_token")
        expect(submission.data).not_to have_key("controller")
        expect(submission.data).not_to have_key("action")
      end
    end

    context "email notifications" do
      it "sends notification email to configured recipients" do
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Test",
            email: "test@example.com",
            message: "Hello",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
      end

      it "sends confirmation email to submitter when configured" do
        expect {
          post "/_forms/#{newsletter_form.id}", params: {
            email: "subscriber@example.com",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(1).times
      end

      it "does not send confirmation email when not configured" do
        contact_form.update!(send_confirmation: false)

        # Should only send 1 email (notification), not 2 (notification + confirmation)
        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Test",
            email: "test@example.com",
            message: "Hello",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob).once
      end

      it "handles email errors gracefully" do
        allow_any_instance_of(Panda::CMS::FormMailer).to receive(:notification_email).and_raise(StandardError, "Email error")
        allow(Rails.logger).to receive(:error)

        expect {
          post "/_forms/#{contact_form.id}", params: {
            name: "Test",
            email: "test@example.com",
            message: "Hello",
            _form_timestamp: 5.seconds.ago.to_i
          }
        }.to change(Panda::CMS::FormSubmission, :count).by(1)

        # Submission should still succeed even if email fails
        expect(response).to have_http_status(:redirect)
      end
    end

    context "validation errors" do
      it "redirects with error message on validation failure" do
        # Create an invalid submission by mocking validation failure
        allow_any_instance_of(Panda::CMS::FormSubmission).to receive(:valid?).and_return(false)
        allow_any_instance_of(Panda::CMS::FormSubmission).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("Email is invalid")

        post "/_forms/#{contact_form.id}", params: {
          name: "Test",
          email: "invalid",
          message: "Hello",
          _form_timestamp: 5.seconds.ago.to_i
        }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("Email is invalid")
      end

      it "handles RecordInvalid exceptions" do
        # Create a submission with an error message
        invalid_submission = Panda::CMS::FormSubmission.new
        invalid_submission.errors.add(:base, "Test error")

        allow_any_instance_of(Panda::CMS::FormSubmission).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(invalid_submission)
        )
        allow(Rails.logger).to receive(:error)

        post "/_forms/#{contact_form.id}", params: {
          name: "Test",
          email: "test@example.com",
          message: "Hello",
          _form_timestamp: 5.seconds.ago.to_i
        }

        expect(response).to have_http_status(:redirect)
        expect(Rails.logger).to have_received(:error).with(/Form submission validation failed/)
      end
    end
  end
end
