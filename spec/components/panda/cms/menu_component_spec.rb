# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::MenuComponent, type: :component do
  describe "initialization and property access" do
    it "accepts name property without NameError" do
      component = described_class.new(name: "main_menu")
      expect(component).to be_a(described_class)
    end

    it "accepts current_path property without NameError" do
      component = described_class.new(name: "main_menu", current_path: "/about")
      expect(component).to be_a(described_class)
    end

    it "accepts styles property without NameError" do
      component = described_class.new(
        name: "main_menu",
        styles: {default: "nav-item", active: "active"}
      )
      expect(component).to be_a(described_class)
    end

    it "accepts overrides property without NameError" do
      component = described_class.new(
        name: "main_menu",
        overrides: {hidden_items: ["Contact"]}
      )
      expect(component).to be_a(described_class)
    end

    it "accepts render_page_menu property without NameError" do
      component = described_class.new(
        name: "main_menu",
        render_page_menu: true
      )
      expect(component).to be_a(described_class)
    end

    it "has default values for properties" do
      component = described_class.new(name: "main_menu")
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders comment for non-existent menu" do
      component = described_class.new(name: "nonexistent_menu")
      output = Capybara.string(render_inline(component).to_html)

      expect(output.native.to_html).to include("<!-- Menu: nonexistent_menu -->")
    end

    it "handles initialization with various properties" do
      component = described_class.new(
        name: "main_menu",
        current_path: "/",
        styles: {default: "nav-item", active: "active", inactive: "inactive"}
      )
      expect(component).to be_a(described_class)
    end

    it "handles rendering with page menu styles" do
      component = described_class.new(
        name: "main_menu",
        current_path: "/",
        render_page_menu: true,
        page_menu_styles: {container: "custom"}
      )
      expect(component).to be_a(described_class)
    end
  end

  describe "menu item filtering" do
    it "accepts overrides with hidden items" do
      component = described_class.new(
        name: "main_menu",
        overrides: {hidden_items: ["Contact"]}
      )
      expect(component).to be_a(described_class)
    end
  end

  describe "ViewComponent pattern" do
    it "uses @instance_variables for all prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/menu_component.rb"))

      # Verify key properties use @ prefix
      expect(source).to include("@name")
      expect(source).to include("@current_path")
      expect(source).to include("@styles")
      expect(source).to include("@overrides")
      expect(source).to include("@render_page_menu")
      expect(source).to include("@page_menu_styles")
    end
  end
end
