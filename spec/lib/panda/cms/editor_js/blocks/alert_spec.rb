require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Alert, :editorjs do
  include EditorHelpers

  let(:alert_primary) do
    {
      "message" => "This is an important message",
      "type" => "primary"
    }
  end

  let(:alert_warning) do
    {
      "message" => "Warning! Something needs attention",
      "type" => "warning"
    }
  end

  it "renders primary alert correctly" do
    rendered = described_class.new(alert_primary).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<div class="bg-blue-100 text-blue-800 p-4 mb-4 rounded-lg">' \
        "This is an important message" \
      "</div>"
    ))
  end

  it "renders warning alert correctly" do
    rendered = described_class.new(alert_warning).render
    expect(normalize_html(rendered)).to eq(normalize_html(
      '<div class="bg-yellow-100 text-yellow-800 p-4 mb-4 rounded-lg">' \
        "Warning! Something needs attention" \
      "</div>"
    ))
  end
end
