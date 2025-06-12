require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Header, :editorjs do
  include EditorJsHelper

  let(:h2_header) do
    {"text" => "Main Header", "level" => 2}
  end

  let(:h3_header) do
    {"text" => "Sub Header", "level" => 3}
  end

  it "renders h2 headers correctly" do
    rendered = described_class.new(h2_header).render
    expect(normalize_html(rendered)).to eq(normalize_html("<h2>Main Header</h2>"))
  end

  it "renders h3 headers correctly" do
    rendered = described_class.new(h3_header).render
    expect(normalize_html(rendered)).to eq(normalize_html("<h3>Sub Header</h3>"))
  end
end
