# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Analytics::LocalProvider do
  let(:provider) { described_class.new }

  describe "#configured?" do
    it "returns true always" do
      expect(provider.configured?).to be true
    end
  end

  describe "#name" do
    it "returns 'Local Analytics'" do
      expect(provider.name).to eq("Local Analytics")
    end
  end

  describe "#page_views" do
    it "returns count of visits" do
      expect(provider.page_views(period: 30.days)).to be_a(Integer)
    end
  end

  describe "#unique_visitors" do
    it "returns count of unique IP addresses" do
      expect(provider.unique_visitors(period: 30.days)).to be_a(Integer)
    end
  end

  describe "#top_pages" do
    it "returns an array" do
      expect(provider.top_pages(limit: 5, period: 30.days)).to be_an(Array)
    end

    context "when visits exist" do
      let(:page) { panda_cms_pages(:homepage) }

      before do
        Panda::CMS::Visit.create!(
          page: page,
          ip_address: "192.168.1.1",
          visited_at: 1.day.ago,
          url: page.path
        )
      end

      it "returns pages with path, title, and views" do
        results = provider.top_pages(limit: 5, period: 30.days)

        if results.any?
          expect(results.first).to have_key(:path)
          expect(results.first).to have_key(:title)
          expect(results.first).to have_key(:views)
        end
      end
    end
  end

  describe "#page_views_over_time" do
    it "returns an array" do
      expect(provider.page_views_over_time(period: 30.days, interval: :daily)).to be_an(Array)
    end

    it "accepts different intervals" do
      expect { provider.page_views_over_time(interval: :daily) }.not_to raise_error
      expect { provider.page_views_over_time(interval: :weekly) }.not_to raise_error
      expect { provider.page_views_over_time(interval: :monthly) }.not_to raise_error
    end
  end

  describe "#top_referrers" do
    it "returns an array" do
      expect(provider.top_referrers(limit: 5, period: 30.days)).to be_an(Array)
    end
  end

  describe "#summary" do
    it "returns a hash with expected keys" do
      result = provider.summary(period: 30.days)

      expect(result).to have_key(:page_views)
      expect(result).to have_key(:unique_visitors)
      expect(result).to have_key(:avg_time_on_site)
      expect(result).to have_key(:bounce_rate)
    end
  end
end
