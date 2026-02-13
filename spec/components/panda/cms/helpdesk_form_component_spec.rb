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
