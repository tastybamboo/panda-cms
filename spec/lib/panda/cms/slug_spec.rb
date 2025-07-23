# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Slug do
  subject { Panda::CMS::Slug }

  it "converts a string to lowercase" do
    expect(described_class.generate("ThisIsATest")).to eq("thisisatest")
  end

  it "trims whitespace from a string" do
    expect(described_class.generate(" whitespace ")).to eq("whitespace")
  end

  it "replaces & with 'and'" do
    expect(described_class.generate("Something & Something Else")).to eq("something-and-something-else")
  end

  it "replaces '_' with '-'" do
    expect(described_class.generate("Page A_B")).to eq("page-a-b")
  end

  it "replaces multiple instances of '-' with a single '-'" do
    expect(described_class.generate("Page --- Abc")).to eq("page-abc")
  end
end
