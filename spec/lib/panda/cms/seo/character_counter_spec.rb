# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Seo::CharacterCounter do
  let(:limit) { 70 }

  it "returns ok when comfortably within the limit" do
    result = described_class.evaluate("A" * 40, limit: limit)

    expect(result.status).to eq(:ok)
    expect(result.remaining).to eq(30)
    expect(result.over_limit?).to be(false)
  end

  it "returns warning when within 10 characters of the limit" do
    result = described_class.evaluate("A" * 65, limit: limit)

    expect(result.status).to eq(:warning)
    expect(result.remaining).to eq(5)
  end

  it "returns error when the value exceeds the limit" do
    result = described_class.evaluate("A" * 75, limit: limit)

    expect(result.status).to eq(:error)
    expect(result.remaining).to eq(-5)
    expect(result.over_limit?).to be(true)
  end
end
