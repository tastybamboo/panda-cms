# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::RichTextComponent, type: :component do
  let(:page) { panda_cms_pages(:homepage) }
  let(:template) { page.template }
  let(:block) do
    Panda::CMS::Block.find_or_create_by!(
      kind: "rich_text",
      key: :test_content,
      panda_cms_template_id: template.id
    )
  end

  before do
    allow(Panda::CMS::Current).to receive(:page).and_return(page)
  end

  describe "#initialize" do
    it "accepts key parameter" do
      component = described_class.new(key: :custom_key)
      expect(component.key).to eq(:custom_key)
    end

    it "accepts text parameter" do
      component = described_class.new(text: "Custom text")
      expect(component.text).to eq("Custom text")
    end

    it "accepts editable parameter" do
      component = described_class.new(editable: false)
      expect(component.editable).to be false
    end

    it "defaults editable to true" do
      component = described_class.new
      expect(component.editable).to be true
    end

    it "defaults key to :text_component" do
      component = described_class.new
      expect(component.key).to eq(:text_component)
    end

    it "defaults text to Lorem ipsum" do
      component = described_class.new
      expect(component.text).to eq("Lorem ipsum...")
    end
  end

  describe "#valid_editor_js_content?" do
    it "returns true for valid EditorJS format" do
      component = described_class.new
      content = {
        "blocks" => [],
        "version" => "2.28.2"
      }
      expect(component.send(:valid_editor_js_content?, content)).to be true
    end

    it "returns false for content without blocks" do
      component = described_class.new
      content = {"version" => "2.28.2"}
      expect(component.send(:valid_editor_js_content?, content)).to be false
    end

    it "returns false for content without version" do
      component = described_class.new
      content = {"blocks" => []}
      expect(component.send(:valid_editor_js_content?, content)).to be false
    end

    it "returns false for non-hash content" do
      component = described_class.new
      expect(component.send(:valid_editor_js_content?, "string")).to be false
    end

    it "returns false for nil content" do
      component = described_class.new
      expect(component.send(:valid_editor_js_content?, nil)).to be false
    end
  end

  describe "#empty_editor_js_content" do
    it "returns valid EditorJS structure" do
      component = described_class.new
      content = component.send(:empty_editor_js_content)

      expect(content).to be_a(Hash)
      expect(content[:blocks]).to be_an(Array)
      expect(content[:blocks].length).to eq(1)
      expect(content[:blocks].first[:type]).to eq("paragraph")
      expect(content[:version]).to eq("2.28.2")
    end

    it "includes timestamp" do
      component = described_class.new
      content = component.send(:empty_editor_js_content)

      expect(content[:time]).to be_a(Integer)
      expect(content[:time]).to be > 0
    end
  end

  describe "#process_html_content" do
    it "returns empty paragraph for blank content" do
      component = described_class.new
      result = component.send(:process_html_content, "")

      expect(result).to eq("<p></p>")
    end

    it "returns empty paragraph for nil content" do
      component = described_class.new
      result = component.send(:process_html_content, nil)

      expect(result).to eq("<p></p>")
    end

    it "returns HTML unchanged if already HTML" do
      component = described_class.new
      html = "<div>Test content</div>"
      result = component.send(:process_html_content, html)

      expect(result).to eq(html)
    end

    it "wraps plain text in paragraph tags" do
      component = described_class.new
      result = component.send(:process_html_content, "Plain text")

      expect(result).to eq("<p>Plain text</p>")
    end
  end

  describe "#normalize_block" do
    let(:component) { described_class.new }

    it "normalizes paragraph blocks" do
      block = {
        "type" => "paragraph",
        "data" => {"text" => "Test"}
      }

      result = component.send(:normalize_block, block)
      expect(result["data"]["text"]).to eq("Test")
    end

    it "handles empty paragraph text" do
      block = {
        "type" => "paragraph",
        "data" => {"text" => nil}
      }

      result = component.send(:normalize_block, block)
      expect(result["data"]["text"]).to eq("")
    end

    it "normalizes header blocks with level" do
      block = {
        "type" => "header",
        "data" => {"text" => "Heading", "level" => "2"}
      }

      result = component.send(:normalize_block, block)
      expect(result["data"]["text"]).to eq("Heading")
      expect(result["data"]["level"]).to eq(2)
    end

    it "normalizes list blocks with string items" do
      block = {
        "type" => "list",
        "data" => {"items" => ["Item 1", "Item 2"]}
      }

      result = component.send(:normalize_block, block)
      expect(result["data"]["items"]).to eq(["Item 1", "Item 2"])
    end

    it "handles list blocks with nested items" do
      block = {
        "type" => "list",
        "data" => {
          "items" => [
            {"content" => "Item 1", "items" => []},
            "Item 2"
          ]
        }
      }

      result = component.send(:normalize_block, block)
      expect(result["data"]["items"].first).to be_a(Hash)
      expect(result["data"]["items"].last).to eq("Item 2")
    end

    it "returns other block types unchanged" do
      block = {
        "type" => "image",
        "data" => {"url" => "https://example.com/image.jpg"}
      }

      result = component.send(:normalize_block, block)
      expect(result).to eq(block)
    end
  end

  describe "#normalize_editor_content" do
    let(:component) { described_class.new }

    it "adds default version if missing" do
      content = {"blocks" => []}
      result = component.send(:normalize_editor_content, content)

      expect(result["version"]).to eq("2.28.2")
    end

    it "adds timestamp if missing" do
      content = {"blocks" => []}
      result = component.send(:normalize_editor_content, content)

      expect(result["time"]).to be_a(Integer)
    end

    it "normalizes blocks array" do
      content = {
        "blocks" => [
          {"type" => "paragraph", "data" => {"text" => "Test"}}
        ]
      }

      result = component.send(:normalize_editor_content, content)
      expect(result["blocks"]).to be_an(Array)
      expect(result["blocks"].first["data"]["text"]).to eq("Test")
    end

    it "handles empty blocks array" do
      content = {"blocks" => []}
      result = component.send(:normalize_editor_content, content)

      expect(result["blocks"]).to eq([])
    end
  end

  describe "error handling" do
    it "handles errors in before_render gracefully" do
      component = described_class.new(key: :test_content)
      allow(component).to receive(:load_block_content).and_raise(StandardError, "Test error")
      allow(Rails.logger).to receive(:error)

      expect { component.before_render }.not_to raise_error
      expect(Rails.logger).to have_received(:error)
    end

    it "logs errors with content information" do
      component = described_class.new
      error = StandardError.new("Test error")
      allow(Rails.logger).to receive(:error)

      component.send(:handle_error, error)

      expect(Rails.logger).to have_received(:error).with(/RichTextComponent error: Test error/)
    end
  end

  describe "#element_attrs" do
    it "includes panda-cms-content class" do
      component = described_class.new
      # Set minimal state to avoid errors
      component.instance_variable_set(:@editable_state, false)

      attrs = component.send(:element_attrs)
      expect(attrs[:class]).to eq("panda-cms-content")
    end

    it "does not include editor data attributes when not editable" do
      component = described_class.new
      component.instance_variable_set(:@editable_state, false)

      attrs = component.send(:element_attrs)
      expect(attrs[:data]).to be_nil
    end
  end

  describe "component constant" do
    it "defines KIND constant" do
      expect(described_class::KIND).to eq("rich_text")
    end
  end

  describe "content processing" do
    let(:component) { described_class.new }

    it "processes valid JSON EditorJS content" do
      content = '{"blocks":[{"type":"paragraph","data":{"text":"Test"}}],"version":"2.28.2"}'

      result = component.send(:process_content_for_editor, content)
      expect(result).to be_a(Hash)
      expect(result["blocks"]).to be_an(Array)
    end

    it "handles JSON parse errors" do
      component = described_class.new
      allow(component).to receive(:convert_html_to_editor_js).and_return(component.send(:empty_editor_js_content))

      result = component.send(:process_content_for_editor, "invalid json{")
      expect(result).to be_a(Hash)
      expect(result[:blocks]).to be_an(Array)
    end
  end
end
