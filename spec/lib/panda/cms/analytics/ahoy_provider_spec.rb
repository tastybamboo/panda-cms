# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Analytics::AhoyProvider do
  let(:provider) { described_class.new(config) }
  let(:config) { {} }

  describe "class metadata" do
    it "has correct slug" do
      expect(described_class.slug).to eq(:ahoy)
    end

    it "has correct display_name" do
      expect(described_class.display_name).to eq("Ahoy")
    end

    it "has correct icon" do
      expect(described_class.icon).to eq("fa-solid fa-anchor")
    end

    it "does not have a settings page" do
      expect(described_class.has_settings_page?).to be false
    end
  end

  describe "#configured?" do
    context "when Ahoy::Visit is defined" do
      before do
        stub_const("Ahoy::Visit", Class.new)
      end

      it "returns true" do
        expect(provider.configured?).to be true
      end
    end

    context "when Ahoy is not available" do
      before do
        hide_const("Ahoy") if defined?(Ahoy)
      end

      it "returns false" do
        expect(provider.configured?).to be false
      end
    end
  end

  describe "#supports_tracking?" do
    it "returns true" do
      expect(provider.supports_tracking?).to be true
    end
  end

  describe "#tracking_configured?" do
    context "when Ahoy is available and tracking is enabled" do
      let(:config) { {enabled: true, tracking_enabled: true} }

      before do
        stub_const("Ahoy::Visit", Class.new)
      end

      it "returns true" do
        expect(provider.tracking_configured?).to be true
      end
    end

    context "when tracking is not enabled" do
      let(:config) { {enabled: true, tracking_enabled: false} }

      before do
        stub_const("Ahoy::Visit", Class.new)
      end

      it "returns false" do
        expect(provider.tracking_configured?).to be false
      end
    end

    context "when Ahoy is not available" do
      let(:config) { {enabled: true, tracking_enabled: true} }

      before do
        hide_const("Ahoy") if defined?(Ahoy)
      end

      it "returns false" do
        expect(provider.tracking_configured?).to be false
      end
    end
  end

  describe "#tracking_script" do
    context "when tracking is configured" do
      let(:config) { {enabled: true, tracking_enabled: true} }

      before do
        stub_const("Ahoy::Visit", Class.new)
      end

      it "returns ahoy.js script tag" do
        result = provider.tracking_script
        expect(result).to include("ahoy.js")
        expect(result).to be_html_safe
      end
    end

    context "when tracking is not configured" do
      it "returns nil" do
        expect(provider.tracking_script).to be_nil
      end
    end
  end

  describe "#name" do
    it "returns 'Ahoy'" do
      expect(provider.name).to eq("Ahoy")
    end
  end
end
