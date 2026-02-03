# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::FormMailer, type: :mailer do
  let(:contact_form) { panda_cms_forms(:contact_form) }
  let(:newsletter_form) { panda_cms_forms(:newsletter_form) }

  describe "#notification_email" do
    let(:submission_data) do
      {
        "name" => "John Doe",
        "email" => "john@example.com",
        "message" => "Test message"
      }
    end
    let(:form_submission) do
      Panda::CMS::FormSubmission.create!(
        form: contact_form,
        data: submission_data
      )
    end

    it "creates email with default subject when not configured" do
      contact_form.update!(notification_subject: nil)
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to match(/Contact Form: \d{2} \w+ \d{4} \d{2}:\d{2}/)
    end

    it "uses configured notification subject" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to eq("New Contact Submission")
    end

    it "processes template variables in subject" do
      contact_form.update!(notification_subject: "Message from {{name}}")
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to eq("Message from John Doe")
    end

    it "sends to specified recipients" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com", "support@example.com"]
      )

      expect(mail.to).to eq(["admin@example.com", "support@example.com"])
    end

    it "uses form's notification_email_list when recipients not provided" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission
      )

      expect(mail.to).to eq(["admin@example.com"])
    end

    it "returns nil when recipients are blank" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: []
      )

      expect(mail.message).to be_an(ActionMailer::Base::NullMail)
    end

    it "sets reply-to when sender email is present" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.reply_to).to include("john@example.com")
    end

    it "uses sender name in reply-to" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail[:reply_to].to_s).to include("John Doe")
    end

    it "finds email field by field_type" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.reply_to).to include("john@example.com")
    end

    it "finds name field by name pattern" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail[:reply_to].to_s).to include("John Doe")
    end

    it "falls back to first_name + last_name pattern when name field not found" do
      submission_data_with_names = {
        "first_name" => "Jane",
        "last_name" => "Smith",
        "email" => "jane@example.com"
      }
      form_submission_with_names = Panda::CMS::FormSubmission.create!(
        form: newsletter_form,
        data: submission_data_with_names
      )

      mail = described_class.notification_email(
        form: newsletter_form,
        form_submission: form_submission_with_names,
        recipients: ["admin@example.com"]
      )

      expect(mail[:reply_to].to_s).to include("Jane Smith")
    end

    it "uses email as name when no name fields found" do
      submission_data_no_name = {
        "email" => "test@example.com",
        "message" => "Hello"
      }
      form_submission_no_name = Panda::CMS::FormSubmission.create!(
        form: newsletter_form,
        data: submission_data_no_name
      )

      mail = described_class.notification_email(
        form: newsletter_form,
        form_submission: form_submission_no_name,
        recipients: ["admin@example.com"]
      )

      expect(mail[:reply_to].to_s).to include("test@example.com")
    end

    it "sets from address with default values" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.from).to be_present
    end

    it "includes submission data in email body" do
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.body.encoded).to include("John Doe")
      expect(mail.body.encoded).to include("john@example.com")
      expect(mail.body.encoded).to include("Test message")
    end
  end

  describe "#confirmation_email" do
    let(:submission_data) do
      {
        "name" => "Jane Doe",
        "email" => "jane@example.com"
      }
    end
    let(:form_submission) do
      Panda::CMS::FormSubmission.create!(
        form: newsletter_form,
        data: submission_data
      )
    end

    it "uses default subject when not configured" do
      newsletter_form.update!(confirmation_subject: nil)
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.subject).to eq("Thank you for your submission")
    end

    it "uses configured confirmation subject" do
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.subject).to eq("Thanks for subscribing!")
    end

    it "processes template variables in subject" do
      newsletter_form.update!(confirmation_subject: "Welcome {{name}}!")
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.subject).to eq("Welcome Jane Doe!")
    end

    it "sends to specified recipient" do
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.to).to eq(["jane@example.com"])
    end

    it "returns nil when recipient is blank" do
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: ""
      )

      expect(mail.message).to be_an(ActionMailer::Base::NullMail)
    end

    it "processes template variables in body" do
      newsletter_form.update!(confirmation_body: "Hello {{name}}, your email is {{email}}")
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.body.encoded).to include("Hello Jane Doe")
      expect(mail.body.encoded).to include("jane@example.com")
    end

    it "sets from address with default values" do
      mail = described_class.confirmation_email(
        form: newsletter_form,
        form_submission: form_submission,
        recipient: "jane@example.com"
      )

      expect(mail.from).to be_present
    end
  end

  describe "#process_template (private method behavior)" do
    let(:form_submission) do
      Panda::CMS::FormSubmission.create!(
        form: contact_form,
        data: {
          "name" => "Test User",
          "email" => "test@example.com",
          "message" => "Test message",
          "interests" => ["Ruby", "Rails", "Testing"]
        }
      )
    end

    it "replaces field placeholders with values" do
      contact_form.update!(notification_subject: "Message from {{name}}")
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to eq("Message from Test User")
    end

    it "handles array values by joining with commas" do
      contact_form.update!(notification_subject: "Interests: {{interests}}")
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to eq("Interests: Ruby, Rails, Testing")
    end

    it "handles missing field gracefully" do
      contact_form.update!(notification_subject: "User: {{nonexistent}}")
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.subject).to eq("User: ")
    end

    it "handles blank template" do
      contact_form.update!(confirmation_body: nil)
      mail = described_class.confirmation_email(
        form: contact_form,
        form_submission: form_submission,
        recipient: "test@example.com"
      )

      expect(mail.body.encoded).not_to include("undefined")
    end
  end

  describe "configuration helpers (via behavior testing)" do
    let(:form_submission) do
      Panda::CMS::FormSubmission.create!(
        form: contact_form,
        data: {
          "name" => "Test User",
          "email" => "test@example.com",
          "message" => "Test message"
        }
      )
    end

    it "uses ActionMailer default_url_options host" do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({host: "example.com"})
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.from).to be_present
    end

    it "falls back to localhost when host not configured" do
      allow(ActionMailer::Base).to receive(:default_url_options).and_return({})
      mail = described_class.notification_email(
        form: contact_form,
        form_submission: form_submission,
        recipients: ["admin@example.com"]
      )

      expect(mail.from).to be_present
    end
  end
end
