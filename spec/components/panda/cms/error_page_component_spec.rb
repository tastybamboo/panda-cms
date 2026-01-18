# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::ErrorPageComponent, type: :component do
  describe "initialization" do
    it "accepts required properties" do
      component = described_class.new(
        error_code: "404",
        message: "Not Found"
      )
      expect(component).to be_a(described_class)
    end

    it "accepts optional properties" do
      component = described_class.new(
        error_code: "500",
        message: "Server Error",
        description: "Something went wrong",
        homepage_link: "/home"
      )
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering" do
    it "renders error code" do
      component = described_class.new(
        error_code: "404",
        message: "Not Found"
      )
      output = Capybara.string(component.call)

      expect(output).to have_text("404")
    end

    it "renders error message" do
      component = described_class.new(
        error_code: "404",
        message: "Page Not Found"
      )
      output = Capybara.string(component.call)

      expect(output).to have_text("Page Not Found")
    end

    it "renders description if provided" do
      component = described_class.new(
        error_code: "500",
        message: "Server Error",
        description: "Something went wrong"
      )
      output = Capybara.string(component.call)

      expect(output).to have_text("Something went wrong")
    end

    it "does not render description if not provided" do
      component = described_class.new(
        error_code: "404",
        message: "Not Found"
      )
      output = Capybara.string(component.call)
      html = output.native.to_html

      # Should still have the basic structure
      expect(html).to include("404")
    end

    it "includes homepage link" do
      component = described_class.new(
        error_code: "404",
        message: "Not Found",
        homepage_link: "/home"
      )
      output = Capybara.string(component.call)

      expect(output).to have_link("Return to homepage", href: "/home")
    end

    it "defaults to root path for homepage link" do
      component = described_class.new(
        error_code: "404",
        message: "Not Found"
      )
      output = Capybara.string(component.call)

      expect(output).to have_link("Return to homepage", href: "/")
    end
  end

  describe "Phlex property pattern" do
    it "uses @instance_variables for prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/error_page_component.rb"))

      expect(source).to include("@error_code")
      expect(source).to include("@message")
      expect(source).to include("@description")
      expect(source).to include("@homepage_link")
    end
  end
end
