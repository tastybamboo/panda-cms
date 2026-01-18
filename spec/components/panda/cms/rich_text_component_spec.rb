# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::RichTextComponent, type: :component do
  describe "initialization and property access" do
    it "accepts key property without NameError" do
      component = described_class.new(key: :test_rich_text, editable: false)
      expect(component).to be_a(described_class)
    end

    it "accepts text property without NameError" do
      component = described_class.new(key: :test_rich_text, text: "Custom text", editable: false)
      expect(component).to be_a(described_class)
    end

    it "accepts editable property without NameError" do
      component = described_class.new(key: :test_rich_text, editable: true)
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
        kind: "rich_text",
        key: :test_rich_text,
        name: "Test Rich Text Block",
        panda_cms_template_id: template.id
      )
    end

    after do
      @block_content&.destroy
      @block&.destroy
    end

    it "renders with panda-cms-content class" do
      @block_content = Panda::CMS::BlockContent.create!(
        block: @block,
        panda_cms_page_id: page.id,
        content: '{"blocks": [{"type": "paragraph", "data": {"text": "Test"}}], "version": "2.28.2"}'
      )

      component = described_class.new(key: :test_rich_text, editable: false)
      output = Capybara.string(component.call)

      expect(output).to have_css("div.panda-cms-content")
    end

    it "successfully initializes component with block" do
      component = described_class.new(key: :test_rich_text, editable: false)
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
      expect { component.call }.not_to raise_error
    end
  end

  describe "Phlex property pattern" do
    it "uses @instance_variables for all prop access" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/rich_text_component.rb"))

      # Verify key properties use @ prefix
      expect(source).to include("@key")
      expect(source).to include("@text")
      expect(source).to include("@editable")
      expect(source).to include("@content")
    end

    it "uses raw() not unsafe_raw()" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/rich_text_component.rb"))
      expect(source).not_to include("unsafe_raw")
      expect(source).to include("raw(")
    end
  end
end
