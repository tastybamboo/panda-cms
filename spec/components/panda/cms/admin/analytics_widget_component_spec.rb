# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::AnalyticsWidgetComponent, type: :component do
  describe "#analytics_available?" do
    it "returns true when local provider is configured" do
      component = described_class.new
      expect(component.analytics_available?).to be true
    end
  end

  describe "#provider" do
    it "returns the analytics provider" do
      component = described_class.new
      expect(component.provider).to be_a(Panda::CMS::Analytics::Provider)
    end
  end

  describe "#period_label" do
    it "returns 'Last 30 days' for default period" do
      component = described_class.new
      expect(component.period_label).to eq("Last 30 days")
    end

    it "returns 'Last 24 hours' for 1.day period" do
      component = described_class.new(period: 1.day)
      expect(component.period_label).to eq("Last 24 hours")
    end

    it "returns 'Last 7 days' for 7.days period" do
      component = described_class.new(period: 7.days)
      expect(component.period_label).to eq("Last 7 days")
    end
  end

  describe "#format_number" do
    it "formats numbers with commas" do
      component = described_class.new
      expect(component.format_number(1234567)).to eq("1,234,567")
    end

    it "returns 'N/A' for nil" do
      component = described_class.new
      expect(component.format_number(nil)).to eq("N/A")
    end
  end

  describe "rendering" do
    it "renders the analytics widget" do
      render_inline(described_class.new)

      expect(page).to have_css("div")
      expect(page).to have_text("Analytics")
    end

    it "displays the period selector" do
      render_inline(described_class.new(period: 30.days))

      expect(page).to have_css("select option[selected]", text: "Last 30 days")
    end

    context "when analytics is available" do
      it "shows summary stats section" do
        render_inline(described_class.new)

        expect(page).to have_text("Page Views")
        expect(page).to have_text("Unique Visitors")
      end
    end
  end
end
