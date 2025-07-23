# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Image, :editorjs do
  include EditorJsHelper

  let(:image_with_caption) do
    {
      "url" => "/path/to/image.jpg",
      "caption" => "Beautiful sunset",
      "withBorder" => true,
      "withBackground" => true,
      "stretched" => true
    }
  end

  let(:simple_image) do
    {
      "url" => "/path/to/image.jpg"
    }
  end

  it "renders image with all options correctly" do
    rendered = described_class.new(image_with_caption).render
    expect(normalize_html(rendered)).to eq(normalize_html(
                                             '<figure class="prose border bg-gray-100 w-full">' \
                                               '<img src="/path/to/image.jpg" alt="Beautiful sunset" />' \
                                               "<figcaption>Beautiful sunset</figcaption>" \
                                             "</figure>"
                                           ))
  end

  it "renders simple image correctly" do
    rendered = described_class.new(simple_image).render
    expect(normalize_html(rendered)).to eq(normalize_html(
                                             '<figure class="prose">' \
                                               '<img src="/path/to/image.jpg" alt="" />' \
                                             "</figure>"
                                           ))
  end
end
