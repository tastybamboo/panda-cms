# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::FormField, type: :model do
  let(:form) { Panda::CMS::Form.create!(name: "Test Form") }

  describe "constants" do
    it "defines FIELD_TYPES with supported field types" do
      expect(described_class::FIELD_TYPES).to eq(%w[text email phone url textarea select checkbox radio file hidden date number signature])
    end
  end

  describe "associations" do
    it "belongs to form" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "text")
      expect(field.form).to eq(form)
    end
  end

  describe "validations" do
    describe "name" do
      it "validates presence of name" do
        field = described_class.new(form: form, label: "Test", field_type: "text")
        expect(field).not_to be_valid
        expect(field.errors[:name]).to include("can't be blank")
      end

      it "validates format of name (lowercase with underscores)" do
        field = described_class.new(form: form, name: "Invalid Name", label: "Test", field_type: "text")
        expect(field).not_to be_valid
        expect(field.errors[:name]).to include("must be lowercase with underscores only")
      end

      it "accepts valid snake_case names" do
        field = described_class.new(form: form, name: "valid_field_name", label: "Test", field_type: "text")
        expect(field).to be_valid
      end

      it "rejects names starting with numbers" do
        field = described_class.new(form: form, name: "123_field", label: "Test", field_type: "text")
        expect(field).not_to be_valid
        expect(field.errors[:name]).to include("must be lowercase with underscores only")
      end

      it "validates uniqueness within form scope" do
        described_class.create!(form: form, name: "duplicate_name", label: "Test 1", field_type: "text")
        field = described_class.new(form: form, name: "duplicate_name", label: "Test 2", field_type: "text")
        expect(field).not_to be_valid
        expect(field.errors[:name]).to include("has already been taken")
      end

      it "allows same name in different forms" do
        other_form = Panda::CMS::Form.create!(name: "Other Form")
        described_class.create!(form: form, name: "same_name", label: "Test 1", field_type: "text")
        field = described_class.new(form: other_form, name: "same_name", label: "Test 2", field_type: "text")
        expect(field).to be_valid
      end
    end

    describe "label" do
      it "validates presence of label" do
        field = described_class.new(form: form, name: "test", field_type: "text")
        expect(field).not_to be_valid
        expect(field.errors[:label]).to include("can't be blank")
      end
    end

    describe "field_type" do
      it "validates presence of field_type" do
        field = described_class.new(form: form, name: "test", label: "Test")
        expect(field).not_to be_valid
        expect(field.errors[:field_type]).to include("can't be blank")
      end

      it "validates inclusion of field_type in FIELD_TYPES" do
        field = described_class.new(form: form, name: "test", label: "Test", field_type: "invalid")
        expect(field).not_to be_valid
        expect(field.errors[:field_type]).to include("is not included in the list")
      end

      described_class::FIELD_TYPES.each do |type|
        it "accepts field_type: #{type}" do
          field = described_class.new(form: form, name: "test", label: "Test", field_type: type)
          expect(field).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    before do
      described_class.create!(form: form, name: "active_field", label: "Active", field_type: "text", active: true, position: 2)
      described_class.create!(form: form, name: "inactive_field", label: "Inactive", field_type: "text", active: false, position: 1)
    end

    describe ".active" do
      it "returns only active fields" do
        expect(form.form_fields.active.pluck(:name)).to eq(["active_field"])
      end
    end

    describe ".ordered" do
      it "returns fields ordered by position" do
        expect(form.form_fields.ordered.pluck(:name)).to eq(["inactive_field", "active_field"])
      end
    end
  end

  describe "#options_list" do
    let(:field) { described_class.new(form: form, name: "test", label: "Test", field_type: "select") }

    it "returns empty array when options is blank" do
      field.options = nil
      expect(field.options_list).to eq([])
    end

    it "returns empty array when options is empty string" do
      field.options = ""
      expect(field.options_list).to eq([])
    end

    it "parses valid JSON array" do
      field.options = '["Option 1", "Option 2", "Option 3"]'
      expect(field.options_list).to eq(["Option 1", "Option 2", "Option 3"])
    end

    it "returns empty array for invalid JSON" do
      field.options = "not valid json"
      expect(field.options_list).to eq([])
    end
  end

  describe "#options_list=" do
    let(:field) { described_class.new(form: form, name: "test", label: "Test", field_type: "select") }

    it "converts array to JSON string" do
      field.options_list = ["Option A", "Option B"]
      expect(field.options).to eq('["Option A","Option B"]')
    end

    it "stores string as-is" do
      field.options_list = '["Already JSON"]'
      expect(field.options).to eq('["Already JSON"]')
    end
  end

  describe "#validation_rules" do
    let(:field) { described_class.new(form: form, name: "test", label: "Test", field_type: "text") }

    it "returns empty hash when validations is blank" do
      field.validations = nil
      expect(field.validation_rules).to eq({})
    end

    it "parses valid JSON and symbolizes keys" do
      field.validations = '{"min_length": 5, "max_length": 100}'
      expect(field.validation_rules).to eq({min_length: 5, max_length: 100})
    end

    it "returns empty hash for invalid JSON" do
      field.validations = "invalid json"
      expect(field.validation_rules).to eq({})
    end
  end

  describe "#validation_rules=" do
    let(:field) { described_class.new(form: form, name: "test", label: "Test", field_type: "text") }

    it "converts hash to JSON string" do
      field.validation_rules = {min_length: 5, max_length: 100}
      expect(field.validations).to eq('{"min_length":5,"max_length":100}')
    end

    it "stores string as-is" do
      field.validation_rules = '{"already": "json"}'
      expect(field.validations).to eq('{"already": "json"}')
    end
  end

  describe "#file_upload?" do
    it "returns true for file field type" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "file")
      expect(field.file_upload?).to be true
    end

    it "returns false for other field types" do
      %w[text email phone textarea select].each do |type|
        field = described_class.new(form: form, name: "test", label: "Test", field_type: type)
        expect(field.file_upload?).to be false
      end
    end
  end

  describe "#signature?" do
    it "returns true for signature field type" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "signature")
      expect(field.signature?).to be true
    end

    it "returns false for other field types" do
      %w[text email phone textarea select file].each do |type|
        field = described_class.new(form: form, name: "test", label: "Test", field_type: type)
        expect(field.signature?).to be false
      end
    end
  end

  describe "#has_options?" do
    it "returns true for select field type" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "select")
      expect(field.has_options?).to be true
    end

    it "returns true for radio field type" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "radio")
      expect(field.has_options?).to be true
    end

    it "returns true for checkbox field type" do
      field = described_class.new(form: form, name: "test", label: "Test", field_type: "checkbox")
      expect(field.has_options?).to be true
    end

    it "returns false for other field types" do
      %w[text email phone textarea file hidden date number signature].each do |type|
        field = described_class.new(form: form, name: "test", label: "Test", field_type: type)
        expect(field.has_options?).to be false
      end
    end
  end

  describe "defaults" do
    it "defaults required to false" do
      field = described_class.create!(form: form, name: "test", label: "Test", field_type: "text")
      expect(field.required).to be false
    end

    it "defaults position to 0" do
      field = described_class.create!(form: form, name: "test", label: "Test", field_type: "text")
      expect(field.position).to eq(0)
    end

    it "defaults active to true" do
      field = described_class.create!(form: form, name: "test", label: "Test", field_type: "text")
      expect(field.active).to be true
    end
  end
end
