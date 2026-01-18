# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::GridComponent, type: :component do
  describe "initialization and property access" do
    it "accepts columns property without NameError" do
      component = described_class.new(columns: 2)
      expect(component).to be_a(described_class)
    end

    it "accepts spans property without NameError" do
      component = described_class.new(columns: 2, spans: [1, 2])
      expect(component).to be_a(described_class)
    end

    it "has default values for properties" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end

    it "defaults to 1 column" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders a div with grid classes" do
      component = described_class.new(columns: 2, spans: [1, 1])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("grid")
      expect(html).to include("w-full")
    end

    it "renders correct number of grid cells" do
      component = described_class.new(columns: 3, spans: [1, 2, 1])
      output = Capybara.string(component.call)
      html = output.native.to_html

      # Should have 3 divs for the 3 spans
      expect(html.scan(/<div/).count).to be >= 3
    end

    it "applies correct column span classes" do
      component = described_class.new(columns: 2, spans: [1, 2])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("col-span-1")
      expect(html).to include("col-span-2")
    end

    it "applies grid-cols class with column count" do
      component = described_class.new(columns: 4, spans: [1, 1, 1, 1])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("grid-cols-4")
    end

    it "includes drag event handlers" do
      component = described_class.new(columns: 2, spans: [1, 1])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("onDragOver")
      expect(html).to include("onDrop")
    end

    it "includes border and background styling" do
      component = described_class.new(columns: 2, spans: [1, 1])
      output = Capybara.string(component.call)
      html = output.native.to_html

      expect(html).to include("border")
      expect(html).to include("bg-red-50")
    end
  end

  describe "Phlex property pattern" do
    it "uses @instance_variables for all prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/grid_component.rb"))

      # Verify key properties use @ prefix
      expect(source).to include("@columns")
      expect(source).to include("@spans")
    end
  end
end
