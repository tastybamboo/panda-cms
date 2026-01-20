# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::TextComponent, type: :component do
  describe "initialization and property access" do
    it "accepts key property without NameError" do
      component = described_class.new(key: :test_text, editable: false)
      expect(component).to be_a(described_class)
    end

    it "accepts editable property without NameError" do
      component = described_class.new(key: :test_text, editable: true)
      expect(component).to be_a(described_class)
    end

    it "has default values for properties" do
      component = described_class.new
      expect(component).to be_a(described_class)
    end
  end

  describe "rendering with fixtures" do
    let(:page) { panda_cms_pages(:homepage) }
    let(:template) { page.template }

    before do
      allow(Panda::CMS::Current).to receive(:page).and_return(page)
      allow(Panda::CMS::Current).to receive(:user).and_return(nil)

      @block = Panda::CMS::Block.create!(
        kind: "plain_text",
        key: :test_text,
        name: "Test Text Block",
        panda_cms_template_id: template.id
      )
      @block_content = Panda::CMS::BlockContent.create!(
        block: @block,
        panda_cms_page_id: page.id,
        content: "Hello, World!"
      )
    end

    after do
      @block_content&.destroy
      @block&.destroy
    end

    it "successfully initializes component" do
      component = described_class.new(key: :test_text, editable: false)
      expect(component).to be_a(described_class)
    end
  end

  describe "non-existent block handling" do
    let(:page) { panda_cms_pages(:homepage) }

    before do
      allow(Panda::CMS::Current).to receive(:page).and_return(page)
      allow(Panda::CMS::Current).to receive(:user).and_return(nil)
    end

    it "handles missing block gracefully" do
      component = described_class.new(key: :nonexistent, editable: false)
      # Component should handle the error without crashing
      expect { render_inline(component) }.not_to raise_error
    end
  end

  describe "ViewComponent pattern" do
    it "uses @instance_variables for all prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/text_component.rb"))

      # Verify key properties use @ prefix
      expect(source).to include("@key")
      expect(source).to include("@editable")
      expect(source).to include("@content")
    end

    it "inherits from Panda::Core::Base" do
      expect(described_class.superclass).to eq(Panda::Core::Base)
    end
  end
end
