# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::HtmlToEditorJsConverter, :editorjs do
  describe ".convert" do
    subject(:convert) { described_class.convert(html) }

    context "with blank input" do
      let(:html) { "" }

      it "returns an empty hash" do
        expect(convert).to eq({})
      end
    end

    context "with existing EditorJS content" do
      let(:html) do
        {
          "time" => 1234567890,
          "blocks" => [
            {
              "type" => "paragraph",
              "data" => {"text" => "Existing content"}
            }
          ],
          "version" => "2.28.2"
        }
      end

      it "returns the content unchanged" do
        expect(convert).to eq(html)
      end
    end

    context "with simple paragraph" do
      let(:html) { "<p>Simple paragraph text</p>" }

      it "converts to EditorJS format" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "paragraph",
            "data" => {"text" => "Simple paragraph text"}
          }
        )
      end
    end

    context "with multiple paragraphs separated by br tags" do
      let(:html) { "<p>First paragraph<br><br>Second paragraph<br><br>Third paragraph</p>" }

      it "creates separate paragraph blocks" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "paragraph",
            "data" => {"text" => "First paragraph"}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => "Second paragraph"}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => "Third paragraph"}
          }
        )
      end
    end

    context "with inline formatting" do
      let(:html) do
        '<p>Text with <strong>bold</strong> and <em>italic</em> and <a href="https://example.com">link</a></p>'
      end

      it "preserves inline HTML formatting" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "paragraph",
            "data" => {
              "text" => 'Text with <b>bold</b> and <i>italic</i> and <a href="https://example.com">link</a>'
            }
          }
        )
      end
    end

    context "with email links" do
      let(:html) do
        '<p>Contact us at <a href="mailto:test@example.com">test@example.com</a></p>'
      end

      it "handles mailto links correctly" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "paragraph",
            "data" => {
              "text" => 'Contact us at <a href="mailto:test@example.com">test@example.com</a>'
            }
          }
        )
      end
    end

    context "with headers" do
      let(:html) do
        <<~HTML
          <h1>Main Title</h1>
          <p>Some text</p>
          <h2>Subtitle</h2>
          <p>More text</p>
        HTML
      end

      it "converts headers to the correct format" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "header",
            "data" => {"text" => "Main Title", "level" => 1}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => "Some text"}
          },
          {
            "type" => "header",
            "data" => {"text" => "Subtitle", "level" => 2}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => "More text"}
          }
        )
      end
    end

    context "with lists" do
      let(:html) do
        <<~HTML
          <ul>
            <li>First item</li>
            <li>Second item</li>
          </ul>
          <ol>
            <li>Numbered one</li>
            <li>Numbered two</li>
          </ol>
        HTML
      end

      it "converts lists to the correct format" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "list",
            "data" => {
              "style" => "unordered",
              "items" => ["First item", "Second item"]
            }
          },
          {
            "type" => "list",
            "data" => {
              "style" => "ordered",
              "items" => ["Numbered one", "Numbered two"]
            }
          }
        )
      end
    end

    context "with blockquotes" do
      let(:html) do
        "<blockquote>A wise quote</blockquote>"
      end

      it "converts blockquotes to the correct format" do
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "quote",
            "data" => {
              "text" => "A wise quote",
              "caption" => "",
              "alignment" => "left"
            }
          }
        )
      end
    end

    context "with complex nested content" do
      let(:html) do
        <<~HTML
          <div>
            <h1>Welcome</h1>
            <p>First paragraph with <strong>bold</strong> text.<br><br>
            Second paragraph with <a href="mailto:test@example.com">email link</a>.</p>
            <ul>
              <li>List item with <em>italic</em></li>
              <li>Another item</li>
            </ul>
            <blockquote>A quote with <strong>emphasis</strong></blockquote>
          </div>
        HTML
      end

      it "handles complex nested content correctly" do
        expect(convert["blocks"]).to match_array([
          {
            "type" => "header",
            "data" => {"text" => "Welcome", "level" => 1}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => "First paragraph with <b>bold</b> text."}
          },
          {
            "type" => "paragraph",
            "data" => {"text" => 'Second paragraph with <a href="mailto:test@example.com">email link</a>.'}
          },
          {
            "type" => "list",
            "data" => {
              "style" => "unordered",
              "items" => ["List item with <i>italic</i>", "Another item"]
            }
          },
          {
            "type" => "quote",
            "data" => {
              "text" => "A quote with <b>emphasis</b>",
              "caption" => "",
              "alignment" => "left"
            }
          }
        ])
      end
    end

    context "with invalid HTML" do
      let(:html) { "<p>Unclosed paragraph" }

      it "handles invalid HTML gracefully" do
        expect { convert }.not_to raise_error
        expect(convert["blocks"]).to contain_exactly(
          {
            "type" => "paragraph",
            "data" => {"text" => "Unclosed paragraph"}
          }
        )
      end
    end
  end
end
