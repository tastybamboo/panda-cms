# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Form Submissions", type: :request do
  # Form submission route is in main app routes, not engine routes
  # See lib/panda/cms/engine/route_config.rb line 16

  # Stub email delivery for all tests
  before do
    allow_any_instance_of(Panda::CMS::FormMailer).to receive(:notification_email).and_return(
      double("mailer", deliver_now: true)
    )
    # Clear cache to prevent rate limiting across tests
    Rails.cache.clear
  end

  let(:form) do
    Panda::CMS::Form.create!(
      name: "Test Form"
    )
  end

  describe "spam protection" do
    describe "timing-based detection" do
      it "rejects submissions that are too fast (< 3 seconds)" do
        # Simulate a form submitted 1 second after loading
        timestamp = 1.second.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Test User",
          email: "test@example.com"
        }, headers: { "HTTP_REFERER" => "/" }

        # Debug output
        if response.status != 302
          puts "Response status: #{response.status}"
          puts "Response body: #{response.body[0..500]}"
        end

        # Should redirect (spam detected)
        expect(response).to be_redirect
        # Should not create submission
        expect(form.form_submissions.count).to eq(0)
      end

      it "rejects submissions that are too old (> 24 hours)" do
        # Simulate a form loaded 25 hours ago
        timestamp = 25.hours.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Test User",
          email: "test@example.com"
        }

        expect(response).to be_redirect
        expect(form.form_submissions.count).to eq(0)
      end

      it "accepts submissions with valid timing (3-24 hours)" do
        # Simulate a form loaded 5 seconds ago
        timestamp = 5.seconds.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Test User",
          email: "test@example.com",
          message: "Valid message"
        }

        expect(response).to be_redirect
        expect(form.form_submissions.count).to eq(1)

        submission = form.form_submissions.last
        expect(submission.data["name"]).to eq("Test User")
      end

      it "accepts submissions without timestamp (graceful degradation)" do
        # Some forms might not have the timestamp field
        post "/_forms/#{form.id}", params: {
          name: "Test User",
          email: "test@example.com"
        }

        expect(response).to be_redirect
        expect(form.form_submissions.count).to eq(1)
      end
    end

    describe "content-based spam detection" do
      it "rejects messages with too many URLs (> 3)" do
        timestamp = 5.seconds.ago.to_i
        spam_message = "Check out https://spam1.com https://spam2.com https://spam3.com https://spam4.com"

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          message: spam_message
        }

        expect(response).to be_redirect
        expect(form.form_submissions.count).to eq(0)
      end

      it "accepts messages with few URLs (<= 3)" do
        timestamp = 5.seconds.ago.to_i
        valid_message = "Check my portfolio at https://example.com and GitHub https://github.com/user"

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Developer",
          message: valid_message
        }

        expect(response).to be_redirect
        expect(form.form_submissions.count).to eq(1)
      end
    end

    describe "rate limiting" do
      before do
        Rails.cache.clear
      end

      it "allows up to 3 submissions per IP per 5 minutes" do
        timestamp = 5.seconds.ago.to_i

        # First 3 submissions should succeed
        3.times do |i|
          post "/_forms/#{form.id}", params: {
            _form_timestamp: timestamp,
            name: "User #{i}"
          }
          expect(response).to be_redirect
        end

        expect(form.form_submissions.count).to eq(3)
      end

      it "blocks 4th submission from same IP within 5 minutes" do
        timestamp = 5.seconds.ago.to_i

        # First 3 submissions
        3.times do |i|
          post "/_forms/#{form.id}", params: {
            _form_timestamp: (5 + i).seconds.ago.to_i,
            name: "User #{i}"
          }
        end

        # 4th submission should be rate limited
        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Blocked User"
        }

        expect(response.status).to eq(429) # Too Many Requests
        expect(form.form_submissions.count).to eq(3)
      end
    end

    describe "IP address and user agent tracking" do
      it "records IP address for submissions" do
        timestamp = 5.seconds.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Test User"
        }, headers: { "REMOTE_ADDR" => "192.168.1.100" }

        submission = form.form_submissions.last
        expect(submission.ip_address).to eq("192.168.1.100")
      end

      it "records user agent for submissions" do
        timestamp = 5.seconds.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          name: "Test User"
        }, headers: { "HTTP_USER_AGENT" => "TestBot/1.0" }

        submission = form.form_submissions.last
        expect(submission.user_agent).to eq("TestBot/1.0")
      end
    end

    describe "parameter cleaning" do
      it "excludes system parameters from submission data" do
        timestamp = 5.seconds.ago.to_i

        post "/_forms/#{form.id}", params: {
          _form_timestamp: timestamp,
          authenticity_token: "token123",
          controller: "form_submissions",
          action: "create",
          spinner: "", # invisible_captcha honeypot
          name: "Test User",
          email: "test@example.com"
        }

        submission = form.form_submissions.last
        expect(submission.data.keys).to contain_exactly("name", "email")
        expect(submission.data).not_to have_key("_form_timestamp")
        expect(submission.data).not_to have_key("authenticity_token")
        expect(submission.data).not_to have_key("spinner")
      end
    end
  end

  describe "successful submissions" do
    it "increments form submission count" do
      timestamp = 5.seconds.ago.to_i
      expect(form.submission_count).to eq(0)

      post "/_forms/#{form.id}", params: {
        _form_timestamp: timestamp,
        name: "Test User"
      }

      form.reload
      expect(form.submission_count).to eq(1)
    end

    it "redirects to completion path if configured" do
      form.update!(completion_path: "/thank-you")
      timestamp = 5.seconds.ago.to_i

      post "/_forms/#{form.id}", params: {
        _form_timestamp: timestamp,
        name: "Test User"
      }

      expect(response).to redirect_to("/thank-you")
    end

    it "redirects back with notice if no completion path" do
      timestamp = 5.seconds.ago.to_i

      post "/_forms/#{form.id}", params: {
        _form_timestamp: timestamp,
        name: "Test User"
      }, headers: { "HTTP_REFERER" => "/contact" }

      expect(response).to be_redirect
      expect(flash[:notice]).to eq("Thank you for your submission!")
    end
  end

  describe "error handling" do
    it "handles invalid form submissions gracefully" do
      timestamp = 5.seconds.ago.to_i

      # Simulate a validation error by stubbing create!
      allow_any_instance_of(Panda::CMS::FormSubmission).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      post "/_forms/#{form.id}", params: {
        _form_timestamp: timestamp,
        name: "Test User"
      }

      expect(response).to be_redirect
      expect(flash[:alert]).to be_present
    end
  end
end
