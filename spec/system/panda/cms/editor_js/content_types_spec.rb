require "system_helper"

RSpec.describe "Editor.js Content Types", type: :system, uses: :editorjs do
  before do
    login_as_admin
    visit new_admin_post_path
    wait_for_editor
  end

  describe "Paragraph content" do
    it "adds and verifies simple paragraph" do
      add_editor_paragraph("Simple paragraph text")

      expect(page).to have_content("Simple paragraph text")
      expect_editor_content_to_include(
        type: "paragraph",
        data: { text: "Simple paragraph text" }
      )
    end

    it "adds and verifies paragraph with formatting" do
      add_editor_paragraph("Text with <b>bold</b> and <i>italic</i>")

      expect(page).to have_content("Text with bold and italic")
      expect(page).to have_css("b", text: "bold")
      expect(page).to have_css("i", text: "italic")
    end
  end

  describe "Header content" do
    it "adds and verifies header with different levels" do
      add_editor_header("Level 1 Header", level: 1)
      add_editor_header("Level 2 Header", level: 2)
      add_editor_header("Level 3 Header", level: 3)

      expect(page).to have_css("h1", text: "Level 1 Header")
      expect(page).to have_css("h2", text: "Level 2 Header")
      expect(page).to have_css("h3", text: "Level 3 Header")
    end

    it "adds and verifies header with formatting" do
      add_editor_header("Header with <b>bold</b>", level: 2)

      expect(page).to have_css("h2") do |header|
        expect(header).to have_css("b", text: "bold")
      end
    end
  end

  describe "List content" do
    it "adds and verifies unordered list" do
      add_editor_list(["First item", "Second item"], type: :unordered)

      expect(page).to have_css("ul") do |list|
        expect(list).to have_css("li", text: "First item")
        expect(list).to have_css("li", text: "Second item")
      end
    end

    it "adds and verifies ordered list" do
      add_editor_list(["Step 1", "Step 2"], type: :ordered)

      expect(page).to have_css("ol") do |list|
        expect(list).to have_css("li", text: "Step 1")
        expect(list).to have_css("li", text: "Step 2")
      end
    end

    it "adds and verifies list with formatting" do
      add_editor_list(["Item with <b>bold</b>", "Item with <i>italic</i>"], type: :unordered)

      expect(page).to have_css("ul") do |list|
        expect(list).to have_css("li b", text: "bold")
        expect(list).to have_css("li i", text: "italic")
      end
    end
  end

  describe "Quote content" do
    it "adds and verifies quote without caption" do
      add_editor_quote("A simple quote")

      expect(page).to have_css("blockquote", text: "A simple quote")
    end

    it "adds and verifies quote with caption" do
      add_editor_quote("An important quote", "Famous Person")

      expect(page).to have_css("blockquote", text: "An important quote")
      expect(page).to have_css("figcaption", text: "Famous Person")
    end

    it "adds and verifies quote with formatting" do
      add_editor_quote("Quote with <b>bold</b>", "Caption with <i>italic</i>")

      expect(page).to have_css("blockquote b", text: "bold")
      expect(page).to have_css("figcaption i", text: "italic")
    end
  end

  private

  def expect_editor_content_to_include(type:, data:)
    content = page.evaluate_script('window.editor.save()')
    blocks = content["blocks"]
    matching_block = blocks.find { |block| block["type"] == type && block["data"].slice(*data.keys) == data }
    expect(matching_block).to be_present, "Expected to find a block of type '#{type}' with data matching #{data}"
  end
end
