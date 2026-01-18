# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::CodeComponent, type: :component do
  describe "initialization and property access" do
    it "accepts key property without NameError" do
      component = described_class.new(key: :test_code, editable: false)
      expect(component).to be_a(described_class)
    end

    it "accepts editable property without NameError" do
      component = described_class.new(key: :test_code, editable: true)
      expect(component).to be_a(described_class)
    end

    it "raises error for invalid key 'code' during initialization" do
      expect {
        described_class.new(key: :code, editable: false)
      }.to raise_error(Panda::CMS::CodeComponent::BlockError, /Key 'code' is not allowed/)
    end
  end

  describe "rendering with fixtures" do
    let(:page) { panda_cms_pages(:homepage) }
    let(:template) { page.template }

    before do
      allow(Panda::CMS::Current).to receive(:page).and_return(page)
      allow(Panda::CMS::Current).to receive(:user).and_return(nil)

      @block = Panda::CMS::Block.create!(
        kind: "code",
        key: :test_code,
        name: "Test Code Block",
        panda_cms_template_id: template.id
      )
      @block_content = Panda::CMS::BlockContent.create!(
        block: @block,
        page: page,
        content: "<p>Test HTML</p>"
      )
    end

    after do
      @block_content&.destroy
      @block&.destroy
    end

    it "renders HTML content without errors" do
      component = described_class.new(key: :test_code, editable: false)
      output = Capybara.string(render_inline(component).to_html)
      expect(output.native.to_html).to include("<p>Test HTML</p>")
    end
  end

  describe "ViewComponent pattern" do
    it "uses raw() not unsafe_raw()" do
      source = File.read(Rails.root.join("../../app/components/panda/cms/code_component.rb"))
      expect(source).not_to include("unsafe_raw")
      expect(source).to include("raw(")
    end

    it "inherits from Panda::Core::Base" do
      expect(described_class.superclass).to eq(Panda::Core::Base)
    end
  end
end
