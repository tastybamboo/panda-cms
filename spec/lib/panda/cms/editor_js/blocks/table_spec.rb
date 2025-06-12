require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Table, :editorjs do
  include EditorJsHelper

  let(:table_with_headers) do
    {
      "withHeadings" => true,
      "content" => [
        ["Name", "Age", "City"],
        ["John", "25", "New York"],
        ["Jane", "30", "London"]
      ]
    }
  end

  let(:table_without_headers) do
    {
      "withHeadings" => false,
      "content" => [
        ["John", "25", "New York"],
        ["Jane", "30", "London"]
      ]
    }
  end

  it "renders table with headers correctly" do
    rendered = described_class.new(table_with_headers).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<div class="overflow-x-auto">' \
        '<table class="min-w-full">' \
          "<tr><th>Name</th><th>Age</th><th>City</th></tr>" \
          "<tr><td>John</td><td>25</td><td>New York</td></tr>" \
          "<tr><td>Jane</td><td>30</td><td>London</td></tr>" \
        "</table>" \
      "</div>"
    ))
  end

  it "renders table without headers correctly" do
    rendered = described_class.new(table_without_headers).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<div class="overflow-x-auto">' \
        '<table class="min-w-full">' \
          "<tr><td>John</td><td>25</td><td>New York</td></tr>" \
          "<tr><td>Jane</td><td>30</td><td>London</td></tr>" \
        "</table>" \
      "</div>"
    ))
  end
end
