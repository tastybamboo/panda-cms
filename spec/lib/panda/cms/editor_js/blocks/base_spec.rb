# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::EditorJs::Blocks::Base, :editorjs do
  let(:test_data) { {"text" => "<script>alert('xss')</script>Safe content"} }
  let(:test_options) { {custom: "option"} }

  subject { described_class.new(test_data, test_options) }

  it "stores data and options" do
    expect(subject.data).to eq(test_data)
    expect(subject.options).to eq(test_options)
  end

  it "provides sanitization" do
    sanitized = subject.send(:sanitize, test_data["text"])
    expect(sanitized).not_to include("<script>")
    expect(sanitized).to include("Safe content")
  end

  it "marks content as html safe" do
    safe_text = subject.send(:html_safe, "test")
    expect(safe_text).to be_html_safe
  end

  it "returns empty string for base render method" do
    expect(subject.render).to eq("")
  end
end
