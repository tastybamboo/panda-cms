# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::PageMenuComponent, type: :component do
  describe "initialization and property access" do
    let(:page) { panda_cms_pages(:homepage) }

    it "accesses page property via @page without NameError" do
      component = described_class.new(page: page, start_depth: 1, styles: {})
      expect(component).to be_a(described_class)
    end

    it "accesses styles property via @styles without NameError" do
      component = described_class.new(page: page, start_depth: 1, styles: {container: "test"})
      expect(component).to be_a(described_class)
    end

    it "accesses start_depth property via @start_depth without NameError" do
      component = described_class.new(page: page, start_depth: 2, styles: {})
      expect(component).to be_a(described_class)
    end

    it "accesses show_heading property via @show_heading without NameError" do
      component = described_class.new(page: page, start_depth: 1, show_heading: false, styles: {})
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    let(:page) { panda_cms_pages(:homepage) }

    before do
      allow(Panda::CMS::Current).to receive(:page).and_return(page)
    end

    it "does not render nav for root page" do
      component = described_class.new(page: page, start_depth: 1, styles: {})
      output = render_inline(component)

      # Root page should not render nav content (returns early in should_render?)
      expect(output).not_to have_css("nav")
    end

    it "accepts custom container styles" do
      component = described_class.new(
        page: page,
        start_depth: 1,
        styles: {container: "custom-nav"}
      )

      # Just verify it initializes without property access errors
      expect(component).to be_a(described_class)
    end
  end
end
