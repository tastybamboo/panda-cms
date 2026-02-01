# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::FormsHelper, type: :helper do
  let(:form) { Panda::CMS::Form.create!(name: "Test Form #{SecureRandom.hex(4)}", status: "active") }

  describe "#render_field_input" do
    it "renders date field with date input type" do
      field = form.form_fields.create!(
        name: "appointment_date",
        label: "Appointment Date",
        field_type: "date",
        required: true
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include('type="date"')
      expect(html).to include('name="appointment_date"')
      expect(html).to include("required")
    end

    it "renders number field with number input type" do
      field = form.form_fields.create!(
        name: "quantity",
        label: "Quantity",
        field_type: "number",
        required: false
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include('type="number"')
      expect(html).to include('name="quantity"')
    end

    it "renders number field with min/max validation rules" do
      field = form.form_fields.create!(
        name: "rating",
        label: "Rating",
        field_type: "number",
        validations: '{"min": 1, "max": 5, "step": 1}'
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include('type="number"')
      expect(html).to include('min="1"')
      expect(html).to include('max="5"')
    end

    it "renders text field correctly" do
      field = form.form_fields.create!(
        name: "name",
        label: "Name",
        field_type: "text",
        placeholder: "Enter your name"
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include('type="text"')
      expect(html).to include('placeholder="Enter your name"')
    end

    it "renders email field correctly" do
      field = form.form_fields.create!(
        name: "email",
        label: "Email",
        field_type: "email"
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include('type="email"')
    end

    it "renders textarea correctly" do
      field = form.form_fields.create!(
        name: "message",
        label: "Message",
        field_type: "textarea"
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include("<textarea")
      expect(html).to include("</textarea>")
    end

    it "renders signature field with informational message" do
      field = form.form_fields.create!(
        name: "signature",
        label: "Signature",
        field_type: "signature"
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include("Signature fields are not available for web form input.")
      expect(html).to include("<p")
    end

    it "renders select with options" do
      field = form.form_fields.create!(
        name: "country",
        label: "Country",
        field_type: "select",
        options: '["UK", "USA", "Canada"]'
      )

      html = helper.send(:render_field_input, field)

      expect(html).to include("<select")
      expect(html).to include("UK")
      expect(html).to include("USA")
      expect(html).to include("Canada")
    end
  end

  describe "#panda_cms_render_form" do
    it "returns nil for forms not accepting submissions" do
      form.update!(status: "archived")

      html = helper.panda_cms_render_form(form)

      expect(html).to be_nil
    end

    it "returns nil for nil form" do
      expect(helper.panda_cms_render_form(nil)).to be_nil
    end
  end
end
