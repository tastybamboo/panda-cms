# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::HelpdeskFormComponent, type: :component do
  describe "constants" do
    it "has KIND set to 'helpdesk_form'" do
      expect(described_class::KIND).to eq("helpdesk_form")
    end
  end

  describe "initialization" do
    it "accepts key property" do
      component = described_class.new(key: :helpdesk_form, editable: false)
      expect(component).to be_a(described_class)
    end

    it "defaults editable to true" do
      component = described_class.new(key: :helpdesk_form)
      expect(component.editable).to be true
    end

    it "accepts sign_in_message parameter" do
      component = described_class.new(key: :helpdesk_form, sign_in_message: "Please sign in")
      expect(component.sign_in_message).to eq("Please sign in")
    end

    it "accepts return_to parameter" do
      component = described_class.new(key: :helpdesk_form, return_to: "/thank-you")
      expect(component.return_to).to eq("/thank-you")
    end

    it "defaults sign_in_message to nil" do
      component = described_class.new(key: :helpdesk_form)
      expect(component.sign_in_message).to be_nil
    end

    it "defaults return_to to nil" do
      component = described_class.new(key: :helpdesk_form)
      expect(component.return_to).to be_nil
    end
  end

  describe "#should_cache?" do
    it "returns false because form depends on auth state" do
      component = described_class.new(key: :helpdesk_form)
      expect(component.should_cache?).to be false
    end
  end

  describe "#helpdesk_available?" do
    it "checks if Panda::Helpdesk is defined" do
      component = described_class.new(key: :helpdesk_form)
      # In the CMS test environment, helpdesk is not loaded
      result = component.send(:helpdesk_available?)
      if defined?(Panda::Helpdesk)
        expect(result).to be_truthy
      else
        expect(result).to be_falsey
      end
    end
  end
end
