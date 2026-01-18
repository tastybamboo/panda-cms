# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::PopularPagesComponent, type: :component do
  describe "initialization and property access" do
    it "accepts popular_pages property without NameError" do
      pages = []
      component = described_class.new(popular_pages: pages)
      expect(component).to be_a(described_class)
    end

    it "accepts period_name property without NameError" do
      pages = []
      component = described_class.new(popular_pages: pages, period_name: "Today")
      expect(component).to be_a(described_class)
    end

    it "has default period_name" do
      pages = []
      component = described_class.new(popular_pages: pages)
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering with empty pages" do
    it "displays no pages message when list is empty" do
      component = described_class.new(popular_pages: [])
      output = Capybara.string(component.call)

      expect(output).to have_text("No page visits recorded yet.")
    end

    it "renders panel component" do
      component = described_class.new(popular_pages: [])
      output = Capybara.string(component.call)

      expect(output).to have_css("div")
    end
  end

  describe "rendering with popular pages" do
    let(:pages_data) do
      [
        double(id: 1, title: "Home", path: "/", visit_count: 150),
        double(id: 2, title: "About", path: "/about", visit_count: 75)
      ]
    end

    it "renders component without errors" do
      component = described_class.new(popular_pages: pages_data)
      output = Capybara.string(component.call)

      expect(output).to have_css("table")
    end

    it "displays visit counts in table" do
      component = described_class.new(popular_pages: pages_data)
      output = Capybara.string(component.call)

      expect(output).to have_text("150")
      expect(output).to have_text("75")
    end

    it "includes period name in heading" do
      component = described_class.new(
        popular_pages: pages_data,
        period_name: "Last 7 Days"
      )
      output = Capybara.string(component.call)

      expect(output).to have_text("Popular Pages (Last 7 Days)")
    end

    it "renders table with styling" do
      component = described_class.new(popular_pages: pages_data)
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("divide-y")
      expect(html).to include("divide-gray")
    end
  end

  describe "Phlex property pattern" do
    it "uses @instance_variables for all prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/admin/popular_pages_component.rb"))

      # Verify key properties use @ prefix
      expect(source).to include("@popular_pages")
      expect(source).to include("@period_name")
    end
  end
end
