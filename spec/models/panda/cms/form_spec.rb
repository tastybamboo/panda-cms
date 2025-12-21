# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Form, type: :model do
  describe "associations" do
    let(:form) { described_class.create!(name: "Test Form") }

    it "has many form_fields ordered by position" do
      field2 = form.form_fields.create!(name: "second", label: "Second", field_type: "text", position: 2)
      field1 = form.form_fields.create!(name: "first", label: "First", field_type: "text", position: 1)

      expect(form.form_fields).to eq([field1, field2])
    end

    it "destroys form_fields when destroyed" do
      form.form_fields.create!(name: "test", label: "Test", field_type: "text")
      expect { form.destroy }.to change(Panda::CMS::FormField, :count).by(-1)
    end

    it "has many form_submissions" do
      form.form_submissions.create!(data: {name: "Test"})
      expect(form.form_submissions.count).to eq(1)
    end

    it "accepts nested attributes for form_fields" do
      form.update!(
        form_fields_attributes: [
          {name: "field1", label: "Field 1", field_type: "text"},
          {name: "field2", label: "Field 2", field_type: "email"}
        ]
      )
      expect(form.form_fields.count).to eq(2)
    end

    it "allows destroying form_fields via nested attributes" do
      field = form.form_fields.create!(name: "test", label: "Test", field_type: "text")
      form.update!(form_fields_attributes: [{id: field.id, _destroy: "1"}])
      expect(form.form_fields.count).to eq(0)
    end

    it "rejects blank nested attributes" do
      form.update!(
        form_fields_attributes: [
          {name: "", label: "", field_type: ""}
        ]
      )
      expect(form.form_fields.count).to eq(0)
    end
  end

  describe "validations" do
    describe "name" do
      it "validates presence of name" do
        form = described_class.new
        expect(form).not_to be_valid
        expect(form.errors[:name]).to include("can't be blank")
      end

      it "validates uniqueness of name" do
        described_class.create!(name: "Unique Name")
        form = described_class.new(name: "Unique Name")
        expect(form).not_to be_valid
        expect(form.errors[:name]).to include("has already been taken")
      end
    end

    describe "status" do
      it "allows nil status" do
        form = described_class.new(name: "Test", status: nil)
        expect(form).to be_valid
      end

      %w[active draft archived].each do |status|
        it "allows status: #{status}" do
          form = described_class.new(name: "Test", status: status)
          expect(form).to be_valid
        end
      end

      it "rejects invalid status" do
        form = described_class.new(name: "Test", status: "invalid")
        expect(form).not_to be_valid
        expect(form.errors[:status]).to include("is not included in the list")
      end
    end
  end

  describe "scopes" do
    describe ".published" do
      it "returns only active forms" do
        active = described_class.create!(name: "Scope Active Form #{SecureRandom.hex(4)}", status: "active")
        described_class.create!(name: "Scope Draft Form #{SecureRandom.hex(4)}", status: "draft")
        described_class.create!(name: "Scope Archived Form #{SecureRandom.hex(4)}", status: "archived")

        expect(described_class.published).to include(active)
        expect(described_class.published.count { |f| f.name.start_with?("Scope") }).to eq(1)
      end
    end
  end

  describe "#notification_email_list" do
    let(:form) { described_class.new(name: "Test") }

    it "returns empty array when notification_emails is blank" do
      form.notification_emails = nil
      expect(form.notification_email_list).to eq([])
    end

    it "parses valid JSON array" do
      form.notification_emails = '["admin@example.com", "support@example.com"]'
      expect(form.notification_email_list).to eq(["admin@example.com", "support@example.com"])
    end

    it "parses comma-separated emails as fallback" do
      form.notification_emails = "admin@example.com, support@example.com"
      expect(form.notification_email_list).to eq(["admin@example.com", "support@example.com"])
    end

    it "handles mixed whitespace in comma-separated emails" do
      form.notification_emails = "admin@example.com,  support@example.com , extra@example.com"
      expect(form.notification_email_list).to eq(["admin@example.com", "support@example.com", "extra@example.com"])
    end

    it "removes blank entries from comma-separated list" do
      form.notification_emails = "admin@example.com, , support@example.com"
      expect(form.notification_email_list).to eq(["admin@example.com", "support@example.com"])
    end
  end

  describe "#notification_email_list=" do
    let(:form) { described_class.new(name: "Test") }

    it "converts array to JSON string" do
      form.notification_email_list = ["admin@example.com", "support@example.com"]
      expect(form.notification_emails).to eq('["admin@example.com","support@example.com"]')
    end

    it "removes blank entries from array" do
      form.notification_email_list = ["admin@example.com", "", "support@example.com"]
      expect(form.notification_emails).to eq('["admin@example.com","support@example.com"]')
    end

    it "stores string as-is" do
      form.notification_email_list = "admin@example.com, support@example.com"
      expect(form.notification_emails).to eq("admin@example.com, support@example.com")
    end
  end

  describe "#email_field_for_confirmation" do
    let(:form) { described_class.create!(name: "Test") }

    it "returns nil when send_confirmation is false" do
      form.update!(send_confirmation: false, confirmation_email_field: "email")
      form.form_fields.create!(name: "email", label: "Email", field_type: "email")
      expect(form.email_field_for_confirmation).to be_nil
    end

    it "returns nil when confirmation_email_field is blank" do
      form.update!(send_confirmation: true, confirmation_email_field: "")
      form.form_fields.create!(name: "email", label: "Email", field_type: "email")
      expect(form.email_field_for_confirmation).to be_nil
    end

    it "returns the matching form field" do
      form.update!(send_confirmation: true, confirmation_email_field: "email")
      email_field = form.form_fields.create!(name: "email", label: "Email", field_type: "email")
      expect(form.email_field_for_confirmation).to eq(email_field)
    end

    it "returns nil when field doesn't exist" do
      form.update!(send_confirmation: true, confirmation_email_field: "nonexistent")
      form.form_fields.create!(name: "email", label: "Email", field_type: "email")
      expect(form.email_field_for_confirmation).to be_nil
    end
  end

  describe "#accepting_submissions?" do
    let(:form) { described_class.new(name: "Test") }

    it "returns true when status is nil" do
      form.status = nil
      expect(form.accepting_submissions?).to be true
    end

    it "returns true when status is active" do
      form.status = "active"
      expect(form.accepting_submissions?).to be true
    end

    it "returns false when status is draft" do
      form.status = "draft"
      expect(form.accepting_submissions?).to be false
    end

    it "returns false when status is archived" do
      form.status = "archived"
      expect(form.accepting_submissions?).to be false
    end
  end

  describe "notification settings" do
    it "stores and retrieves notification_subject" do
      form = described_class.create!(name: "Notification Subject Test #{SecureRandom.hex(4)}")
      form.update!(notification_subject: "New Contact Submission")
      expect(form.reload.notification_subject).to eq("New Contact Submission")
    end

    it "stores and retrieves confirmation settings" do
      form = described_class.create!(name: "Confirmation Settings Test #{SecureRandom.hex(4)}")
      form.update!(
        send_confirmation: true,
        confirmation_subject: "Thanks for contacting us",
        confirmation_body: "We received your message, {{name}}!"
      )
      form.reload
      expect(form.send_confirmation).to be true
      expect(form.confirmation_subject).to eq("Thanks for contacting us")
      expect(form.confirmation_body).to eq("We received your message, {{name}}!")
    end

    it "stores and retrieves success_message" do
      form = described_class.create!(name: "Success Message Test #{SecureRandom.hex(4)}")
      form.update!(success_message: "Thank you for your submission!")
      expect(form.reload.success_message).to eq("Thank you for your submission!")
    end

    it "stores and retrieves description" do
      form = described_class.create!(name: "Description Test #{SecureRandom.hex(4)}")
      form.update!(description: "Main contact form for website visitors")
      expect(form.reload.description).to eq("Main contact form for website visitors")
    end
  end
end
