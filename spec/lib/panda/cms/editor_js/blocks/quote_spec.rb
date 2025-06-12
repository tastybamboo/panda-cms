require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Quote, :editorjs do
  include EditorJsHelper

  let(:quote_with_caption) do
    {
      "text" => "Life is like a box of chocolates",
      "caption" => "Forrest Gump",
      "alignment" => "center"
    }
  end

  let(:quote_without_caption) do
    {
      "text" => "Simple quote text",
      "alignment" => "left"
    }
  end

  it "renders quote with caption correctly" do
    rendered = described_class.new(quote_with_caption).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<figure class="text-center">' \
        "<blockquote>" \
          "<p>Life is like a box of chocolates</p>" \
        "</blockquote>" \
        "<figcaption>Forrest Gump</figcaption>" \
      "</figure>"
    ))
  end

  it "renders quote without caption correctly" do
    rendered = described_class.new(quote_without_caption).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<figure class="text-left">' \
        "<blockquote>" \
          "<p>Simple quote text</p>" \
        "</blockquote>" \
      "</figure>"
    ))
  end
end
