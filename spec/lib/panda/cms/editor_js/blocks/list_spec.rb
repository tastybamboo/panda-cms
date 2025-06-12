# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::List, :editorjs do
  include EditorJsHelper

  let(:ordered_list) do
    {
      "style" => "ordered",
      "items" => [
        "First item",
        {
          "content" => "Second item",
          "items" => ["Nested item 1", "Nested item 2"]
        },
        "Third item"
      ]
    }
  end

  let(:unordered_list) do
    {
      "style" => "unordered",
      "items" => ["First item", "Second item"]
    }
  end

  it "renders ordered lists with correct HTML structure" do
    rendered = described_class.new(ordered_list).render
    expect(normalize_html(rendered)).to eq(normalize_html(
                                             "<ol>" \
                                               "<li>First item</li>" \
                                               "<li>Second item" \
                                                 "<ol>" \
                                                   "<li>Nested item 1</li>" \
                                                   "<li>Nested item 2</li>" \
                                                 "</ol>" \
                                               "</li>" \
                                               "<li>Third item</li>" \
                                             "</ol>"
                                           ))
  end

  it "renders unordered lists with correct HTML structure" do
    rendered = described_class.new(unordered_list).render
    expect(normalize_html(rendered)).to eq(normalize_html(
                                             "<ul>" \
                                               "<li>First item</li>" \
                                               "<li>Second item</li>" \
                                             "</ul>"
                                           ))
  end
end
