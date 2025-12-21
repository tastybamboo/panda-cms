# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::FormSubmission, type: :model do
  let(:form) { Panda::CMS::Form.create!(name: "Test Form") }

  describe "associations" do
    it "belongs to form" do
      submission = described_class.new(form: form, data: {name: "Test"})
      expect(submission.form).to eq(form)
    end

    it "has many attached files" do
      submission = described_class.create!(form: form, data: {name: "Test"})
      expect(submission).to respond_to(:files)
      expect(submission.files).to be_an(ActiveStorage::Attached::Many)
    end
  end

  describe "validations" do
    describe "data" do
      it "validates presence of data" do
        submission = described_class.new(form: form, data: nil)
        expect(submission).not_to be_valid
        expect(submission.errors[:data]).to include("can't be blank")
      end

      it "is valid with data present" do
        submission = described_class.new(form: form, data: {name: "Test User"})
        expect(submission).to be_valid
      end
    end

    describe "required field validation" do
      before do
        form.form_fields.create!(
          name: "email",
          label: "Email Address",
          field_type: "email",
          required: true,
          active: true
        )
        form.form_fields.create!(
          name: "name",
          label: "Your Name",
          field_type: "text",
          required: true,
          active: true
        )
        form.form_fields.create!(
          name: "message",
          label: "Message",
          field_type: "textarea",
          required: false,
          active: true
        )
      end

      it "fails validation when required fields are missing" do
        submission = described_class.new(form: form, data: {"message" => "Hello"})
        expect(submission).not_to be_valid
        expect(submission.errors[:base]).to include("Email Address is required")
        expect(submission.errors[:base]).to include("Your Name is required")
      end

      it "passes validation when all required fields are present" do
        submission = described_class.new(
          form: form,
          data: {"email" => "test@example.com", "name" => "Test User"}
        )
        expect(submission).to be_valid
      end

      it "ignores inactive required fields" do
        form.form_fields.find_by(name: "email").update!(active: false)
        submission = described_class.new(
          form: form,
          data: {"name" => "Test User"}
        )
        expect(submission).to be_valid
      end
    end

    describe "email format validation" do
      before do
        form.form_fields.create!(
          name: "email",
          label: "Email Address",
          field_type: "email",
          active: true
        )
      end

      it "passes validation for valid email format" do
        submission = described_class.new(
          form: form,
          data: {"email" => "user@example.com"}
        )
        expect(submission).to be_valid
      end

      it "fails validation for invalid email format" do
        submission = described_class.new(
          form: form,
          data: {"email" => "not-an-email"}
        )
        expect(submission).not_to be_valid
        expect(submission.errors[:base]).to include("Email Address must be a valid email address")
      end

      it "passes validation when email field is blank (unless required)" do
        submission = described_class.new(
          form: form,
          data: {"name" => "Test"}
        )
        expect(submission).to be_valid
      end

      it "passes validation for complex valid email addresses" do
        valid_emails = [
          "user+tag@example.com",
          "user.name@example.co.uk",
          "user123@subdomain.example.org"
        ]

        valid_emails.each do |email|
          submission = described_class.new(form: form, data: {"email" => email})
          expect(submission).to be_valid, "Expected #{email} to be valid"
        end
      end
    end

    describe "phone format validation" do
      before do
        form.form_fields.create!(
          name: "phone",
          label: "Phone Number",
          field_type: "phone",
          active: true
        )
      end

      it "passes validation for valid phone formats" do
        valid_phones = [
          "1234567890",
          "+44 20 7946 0958",
          "(555) 123-4567",
          "+1-800-555-1234"
        ]

        valid_phones.each do |phone|
          submission = described_class.new(form: form, data: {"phone" => phone})
          expect(submission).to be_valid, "Expected #{phone} to be valid"
        end
      end

      it "fails validation for invalid phone formats" do
        submission = described_class.new(
          form: form,
          data: {"phone" => "call me maybe"}
        )
        expect(submission).not_to be_valid
        expect(submission.errors[:base]).to include("Phone Number must be a valid phone number")
      end
    end

    describe "url format validation" do
      before do
        form.form_fields.create!(
          name: "website",
          label: "Website URL",
          field_type: "url",
          active: true
        )
      end

      it "passes validation for valid URL formats" do
        valid_urls = [
          "http://example.com",
          "https://example.com",
          "https://www.example.com/path/to/page",
          "https://subdomain.example.co.uk/page?query=value"
        ]

        valid_urls.each do |url|
          submission = described_class.new(form: form, data: {"website" => url})
          expect(submission).to be_valid, "Expected #{url} to be valid"
        end
      end

      it "fails validation for URLs without protocol" do
        submission = described_class.new(
          form: form,
          data: {"website" => "www.example.com"}
        )
        expect(submission).not_to be_valid
        expect(submission.errors[:base]).to include("Website URL must be a valid URL (starting with http:// or https://)")
      end

      it "fails validation for invalid URLs" do
        submission = described_class.new(
          form: form,
          data: {"website" => "not a url"}
        )
        expect(submission).not_to be_valid
        expect(submission.errors[:base]).to include("Website URL must be a valid URL (starting with http:// or https://)")
      end

      it "passes validation when url field is blank" do
        submission = described_class.new(
          form: form,
          data: {"name" => "Test"}
        )
        expect(submission).to be_valid
      end
    end

    describe "validation with no form fields defined" do
      it "skips field validation when form has no fields" do
        submission = described_class.new(
          form: form,
          data: {"anything" => "goes", "email" => "invalid-email"}
        )
        expect(submission).to be_valid
      end
    end
  end

  describe "form submission tracking" do
    it "stores IP address" do
      submission = described_class.create!(
        form: form,
        data: {name: "Test"},
        ip_address: "192.168.1.1"
      )
      expect(submission.ip_address).to eq("192.168.1.1")
    end

    it "stores user agent" do
      submission = described_class.create!(
        form: form,
        data: {name: "Test"},
        user_agent: "Mozilla/5.0"
      )
      expect(submission.user_agent).to eq("Mozilla/5.0")
    end
  end

  describe "data storage" do
    it "stores hash data as JSONB" do
      data = {
        "name" => "John Doe",
        "email" => "john@example.com",
        "interests" => ["coding", "reading"]
      }
      submission = described_class.create!(form: form, data: data)
      submission.reload
      expect(submission.data).to eq(data)
    end

    it "preserves nested structures" do
      data = {
        "contact" => {"primary" => "email", "secondary" => "phone"},
        "preferences" => ["newsletter", "updates"]
      }
      submission = described_class.create!(form: form, data: data)
      submission.reload
      expect(submission.data["contact"]["primary"]).to eq("email")
    end
  end
end
