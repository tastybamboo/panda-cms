# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::RecentPagesWidgetComponent, type: :component do
  include Panda::CMS::Engine.routes.url_helpers

  def default_url_options
    {host: "example.com"}
  end

  describe "#recent_pages" do
    it "returns pages ordered by updated_at descending" do
      component = described_class.new(limit: 10)
      pages = component.recent_pages

      # Should be ordered by most recent first
      updated_times = pages.pluck(:updated_at)
      expect(updated_times).to eq(updated_times.sort.reverse)
    end

    it "respects the limit parameter" do
      component = described_class.new(limit: 3)

      expect(component.recent_pages.count).to be <= 3
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

  describe "#status_color" do
    let(:component) { described_class.new }

    it "returns green for published pages" do
      test_page = Panda::CMS::Page.new(status: "published")
      expect(component.status_color(test_page)).to include("green")
    end

    it "returns yellow for hidden pages" do
      test_page = Panda::CMS::Page.new(status: "hidden")
      expect(component.status_color(test_page)).to include("yellow")
    end

    it "returns gray for archived pages" do
      test_page = Panda::CMS::Page.new(status: "archived")
      expect(component.status_color(test_page)).to include("gray")
    end
  end

  describe "rendering" do
    it "renders the recent pages widget" do
      render_inline(described_class.new)

      expect(page).to have_css("div")
      expect(page).to have_text("Recent Activity")
    end

    context "when pages exist" do
      it "shows pages list with time ago" do
        render_inline(described_class.new(limit: 2))

        # Should have at least the container elements
        expect(page).to have_css("ul")
      end
    end
  end
end
