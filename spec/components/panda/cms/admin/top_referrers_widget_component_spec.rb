# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::TopReferrersWidgetComponent, type: :component do
  describe "#top_referrers" do
    it "fetches top referrers from provider" do
      component = described_class.new(limit: 5, period: 7.days)
      provider = instance_double(Panda::CMS::Analytics::LocalProvider)

      allow(component).to receive(:provider).and_return(provider)
      allow(provider).to receive(:top_referrers).with(limit: 5, period: 7.days).and_return([
        {source: "google.com", visits: 100},
        {source: "Direct", visits: 50}
      ])

      referrers = component.top_referrers
      expect(referrers).to eq([
        {source: "google.com", visits: 100},
        {source: "Direct", visits: 50}
      ])
    end

    it "returns nil when provider is unavailable" do
      component = described_class.new
      allow(component).to receive(:provider).and_return(nil)

      expect(component.top_referrers).to be_nil
    end

    it "handles errors gracefully" do
      component = described_class.new
      provider = instance_double(Panda::CMS::Analytics::LocalProvider)

      allow(component).to receive(:provider).and_return(provider)
      allow(provider).to receive(:top_referrers).and_raise(StandardError, "API error")
      allow(Rails.logger).to receive(:error)

      expect(component.top_referrers).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Error fetching top referrers/)
    end
  end

  describe "#limit" do
    it "defaults to 10" do
      component = described_class.new
      expect(component.limit).to eq(10)
    end

    it "accepts custom limit" do
      component = described_class.new(limit: 5)
      expect(component.limit).to eq(5)
    end
  end

  describe "rendering" do
    it "renders the top referrers widget" do
      render_inline(described_class.new)

      expect(page).to have_css("div")
      expect(page).to have_text("Top Referrers")
    end

    it "displays the period selector" do
      render_inline(described_class.new(period: 7.days))

      expect(page).to have_css("select option[selected]", text: "Last 7 days")
    end

    context "when referrer data is available" do
      it "shows referrers list" do
        component = described_class.new
        allow(component).to receive(:top_referrers).and_return([
          {source: "google.com", visits: 100},
          {source: "twitter.com", visits: 50}
        ])

        render_inline(component)

        expect(page).to have_text("google.com")
        expect(page).to have_text("100")
        expect(page).to have_text("twitter.com")
        expect(page).to have_text("50")
      end
    end

    context "when no referrer data is available" do
      it "shows empty state message" do
        component = described_class.new
        allow(component).to receive(:top_referrers).and_return(nil)

        render_inline(component)

        expect(page).to have_text("No referrer data available")
      end
    end
  end
end
