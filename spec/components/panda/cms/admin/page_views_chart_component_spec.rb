# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::PageViewsChartComponent, type: :component do
  describe "#page_views_data" do
    it "fetches page views over time from provider" do
      component = described_class.new(period: 7.days, interval: :daily)
      provider = instance_double(Panda::CMS::Analytics::LocalProvider)

      allow(component).to receive(:provider).and_return(provider)
      allow(provider).to receive(:page_views_over_time).with(period: 7.days, interval: :daily).and_return([
        {date: Date.today - 1.day, views: 100},
        {date: Date.today, views: 150}
      ])

      data = component.page_views_data
      expect(data).to eq([
        {date: Date.today - 1.day, views: 100},
        {date: Date.today, views: 150}
      ])
    end

    it "returns nil when provider is unavailable" do
      component = described_class.new
      allow(component).to receive(:provider).and_return(nil)

      expect(component.page_views_data).to be_nil
    end

    it "handles errors gracefully" do
      component = described_class.new
      provider = instance_double(Panda::CMS::Analytics::LocalProvider)

      allow(component).to receive(:provider).and_return(provider)
      allow(provider).to receive(:page_views_over_time).and_raise(StandardError, "API error")
      allow(Rails.logger).to receive(:error)

      expect(component.page_views_data).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Error fetching page views over time/)
    end
  end

  describe "#chartkick_data" do
    it "converts data to Chartkick format" do
      component = described_class.new(interval: :daily)
      allow(component).to receive(:page_views_data).and_return([
        {date: Date.new(2026, 1, 1), views: 100},
        {date: Date.new(2026, 1, 2), views: 150}
      ])

      data = component.chartkick_data
      expect(data).to eq({
        "Jan 01" => 100,
        "Jan 02" => 150
      })
    end

    it "returns empty hash when no data" do
      component = described_class.new
      allow(component).to receive(:page_views_data).and_return(nil)

      expect(component.chartkick_data).to eq({})
    end
  end

  describe "#format_date" do
    let(:component) { described_class.new }

    it "formats daily dates" do
      component = described_class.new(interval: :daily)
      date = Date.new(2026, 1, 15)
      expect(component.format_date(date)).to eq("Jan 15")
    end

    it "formats weekly dates" do
      component = described_class.new(interval: :weekly)
      date = Date.new(2026, 1, 15)
      expect(component.format_date(date)).to eq("Jan 15")
    end

    it "formats monthly dates" do
      component = described_class.new(interval: :monthly)
      date = Date.new(2026, 1, 15)
      expect(component.format_date(date)).to eq("Jan 2026")
    end
  end

  describe "#interval" do
    it "defaults to daily" do
      component = described_class.new
      expect(component.interval).to eq(:daily)
    end

    it "accepts custom interval" do
      component = described_class.new(interval: :weekly)
      expect(component.interval).to eq(:weekly)
    end
  end

  describe "rendering" do
    it "renders the page views chart widget" do
      render_inline(described_class.new)

      expect(page).to have_css("div")
      expect(page).to have_text("Page Views Over Time")
    end

    it "displays the period selector" do
      render_inline(described_class.new(period: 7.days))

      expect(page).to have_css("select option[selected]", text: "Last 7 days")
    end

    context "when no chart data is available" do
      it "shows empty state message" do
        component = described_class.new
        allow(component).to receive(:page_views_data).and_return(nil)

        render_inline(component)

        expect(page).to have_text("No chart data available")
      end
    end
  end
end
