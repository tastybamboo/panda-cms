# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::BaseAnalyticsWidgetComponent, type: :component do
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

    it "returns 'Today' for 1.day period" do
      component = described_class.new(period: 1.day)
      expect(component.period_label).to eq("Today")
    end

    it "returns 'Last 7 days' for 7.days period" do
      component = described_class.new(period: 7.days)
      expect(component.period_label).to eq("Last 7 days")
    end

    it "returns 'Last 90 days' for 90.days period" do
      component = described_class.new(period: 90.days)
      expect(component.period_label).to eq("Last 90 days")
    end

    it "returns 'Last year' for 1.year period" do
      component = described_class.new(period: 1.year)
      expect(component.period_label).to eq("Last year")
    end

    it "returns custom label for other periods" do
      component = described_class.new(period: 15.days)
      expect(component.period_label).to eq("Last 15 days")
    end
  end

  describe "#format_number" do
    it "formats numbers with commas" do
      component = described_class.new
      expect(component.format_number(1234567)).to eq("1,234,567")
    end

    it "handles small numbers" do
      component = described_class.new
      expect(component.format_number(123)).to eq("123")
    end

    it "handles numbers with exactly 3 digits" do
      component = described_class.new
      expect(component.format_number(1000)).to eq("1,000")
    end

    it "returns 'N/A' for nil" do
      component = described_class.new
      expect(component.format_number(nil)).to eq("N/A")
    end
  end

  describe "#default_attrs" do
    it "includes consistent widget styling" do
      component = described_class.new
      expect(component.default_attrs[:class]).to include("bg-white")
      expect(component.default_attrs[:class]).to include("rounded-2xl")
      expect(component.default_attrs[:class]).to include("border")
      expect(component.default_attrs[:class]).to include("p-6")
    end
  end

  describe "#period" do
    it "defaults to 30 days" do
      component = described_class.new
      expect(component.period).to eq(30.days)
    end

    it "accepts custom period" do
      component = described_class.new(period: 7.days)
      expect(component.period).to eq(7.days)
    end
  end
end
