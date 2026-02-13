# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::FormComponent, type: :component do
  before do
    vc_test_controller.class.helper Panda::CMS::FormsHelper
  end

  describe "constants" do
    it "has KIND set to 'form'" do
      expect(described_class::KIND).to eq("form")
    end
  end

  describe "initialization" do
    it "accepts key property" do
      component = described_class.new(key: :contact_form, editable: false)
      expect(component).to be_a(described_class)
    end

    it "defaults editable to true" do
      component = described_class.new(key: :contact_form)
      expect(component.editable).to be true
    end
  end

  describe "rendering with fixtures" do
    let(:page) { panda_cms_pages(:about_page) }
    let(:template) { page.template }
    let(:form) { panda_cms_forms(:contact_form) }

    before do
      allow(Panda::CMS::Current).to receive(:page).and_return(page)
      allow(Panda::CMS::Current).to receive(:user).and_return(nil)
    end

    context "when a valid form ID is stored" do
      it "renders the form" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        expect(output.css("form").length).to be >= 1
      end

      it "renders the form with correct submission URL" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        form_el = output.css("form").first
        expect(form_el["action"]).to include("/_forms/")
      end

      it "includes spam protection fields" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        expect(output.css("input[name='_form_timestamp']")).to be_present
        expect(output.css("input[name='spinner']")).to be_present
      end
    end

    context "when no form is selected (empty content)" do
      before do
        block_content = panda_cms_block_contents(:about_page_contact_form)
        block_content.update_column(:content, "{}")
      end

      it "renders nothing" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        expect(output.css("form")).to be_empty
        expect(output.text.strip).to eq("")
      end
    end

    context "when the referenced form has been deleted (stale ID)" do
      before do
        block_content = panda_cms_block_contents(:about_page_contact_form)
        block_content.update_column(:content, "00000000-0000-0000-0000-000000000000")
      end

      it "renders nothing" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        expect(output.css("form")).to be_empty
        expect(output.text.strip).to eq("")
      end
    end

    context "when the form is not accepting submissions" do
      before do
        form.update_column(:status, "draft")
      end

      it "renders nothing" do
        component = described_class.new(key: :contact_form, editable: false)
        output = render_inline(component)
        expect(output.css("form")).to be_empty
        expect(output.text.strip).to eq("")
      end
    end

    context "when no block exists for the key" do
      it "renders nothing" do
        component = described_class.new(key: :nonexistent_form, editable: false)
        output = render_inline(component)
        expect(output.css("form")).to be_empty
        expect(output.text.strip).to eq("")
      end
    end
  end
end
