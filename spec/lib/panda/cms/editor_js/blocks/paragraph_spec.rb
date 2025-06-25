# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Paragraph, :editorjs do
  include EditorJsHelper

  let(:simple_paragraph) do
    {"text" => "Simple paragraph text"}
  end

  let(:formatted_paragraph) do
    {"text" => "Text with <b>bold</b> formatting"}
  end

  let(:empty_paragraph) do
    {"text" => ""}
  end

  it "renders simple paragraphs correctly" do
    rendered = described_class.new(simple_paragraph).render
    expect(normalize_html(rendered)).to eq(normalize_html("<p>Simple paragraph text</p>"))
  end

  it "preserves allowed HTML formatting" do
    rendered = described_class.new(formatted_paragraph).render
    expect(normalize_html(rendered)).to eq(normalize_html("<p>Text with <b>bold</b> formatting</p>"))
  end

  it "renders nothing for empty paragraphs" do
    rendered = described_class.new(empty_paragraph).render
    expect(rendered).to eq("")
  end
end
