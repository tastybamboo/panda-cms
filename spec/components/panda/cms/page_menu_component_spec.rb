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

  describe "initialization of show_all_items" do
    let(:page) { panda_cms_pages(:homepage) }

    it "defaults show_all_items to false" do
      component = described_class.new(page: page, start_depth: 1, styles: {})
      expect(component.show_all_items).to be false
    end

    it "accepts show_all_items parameter" do
      component = described_class.new(page: page, start_depth: 1, styles: {}, show_all_items: true)
      expect(component.show_all_items).to be true
    end
  end

  describe "should_skip_item? with show_all_items" do
    let(:about_page) { panda_cms_pages(:about_page) }
    let(:team_page) { panda_cms_pages(:about_team_page) }

    it "skips items without a page regardless of show_all_items" do
      component = described_class.new(page: about_page, start_depth: 1, styles: {}, show_all_items: true)
      menu_item = instance_double(Panda::CMS::MenuItem, page: nil)

      expect(component.send(:should_skip_item?, menu_item, 1)).to be true
    end

    it "does not skip items when show_all_items is true and Current.page is nil" do
      allow(Panda::CMS::Current).to receive(:page).and_return(nil)
      component = described_class.new(page: about_page, start_depth: 1, styles: {}, show_all_items: true)
      menu_item = instance_double(Panda::CMS::MenuItem, page: team_page)

      expect(component.send(:should_skip_item?, menu_item, 1)).to be false
    end

    it "skips items when show_all_items is false and Current.page is nil" do
      allow(Panda::CMS::Current).to receive(:page).and_return(nil)
      component = described_class.new(page: about_page, start_depth: 1, styles: {})
      menu_item = instance_double(Panda::CMS::MenuItem, page: team_page)

      expect(component.send(:should_skip_item?, menu_item, 1)).to be true
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
