# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Pro::ContentSource, type: :model do
  describe "validations" do
    it "requires a domain" do
      source = described_class.new(trust_level: :neutral)
      expect(source).not_to be_valid
      expect(source.errors[:domain]).to include("can't be blank")
    end

    it "requires unique domain" do
      described_class.create!(domain: "example.com", trust_level: :neutral)
      source = described_class.new(domain: "example.com", trust_level: :neutral)
      expect(source).not_to be_valid
      expect(source.errors[:domain]).to include("has already been taken")
    end

    it "requires trust_level" do
      source = described_class.new(domain: "example.com", trust_level: nil)
      expect(source).not_to be_valid
      expect(source.errors[:trust_level]).to include("can't be blank")
    end

    it "validates domain format" do
      source = described_class.new(domain: "https://example.com", trust_level: :neutral)
      expect(source).not_to be_valid
      expect(source.errors[:domain]).to include("should be a domain only, not a full URL")
    end

    it "accepts valid domain formats" do
      source = described_class.new(domain: "example.com", trust_level: :neutral)
      expect(source).to be_valid
    end
  end

  describe "enums" do
    it "defines trust_level enum" do
      expect(described_class.trust_levels.keys).to include("always_prefer", "trusted", "neutral", "untrusted", "never_use")
    end
  end

  describe "scopes" do
    before do
      described_class.create!(domain: "prefer.com", trust_level: :always_prefer)
      described_class.create!(domain: "trusted.com", trust_level: :trusted)
      described_class.create!(domain: "neutral.com", trust_level: :neutral)
      described_class.create!(domain: "untrusted.com", trust_level: :untrusted)
    end

    it "filters preferred sources" do
      expect(described_class.preferred.count).to eq(1)
      expect(described_class.preferred.first.domain).to eq("prefer.com")
    end

    it "filters trusted sources" do
      expect(described_class.trusted_sources.count).to eq(2)
    end

    it "filters untrusted sources" do
      expect(described_class.untrusted_sources.count).to eq(1)
    end
  end

  describe "#matches_url?" do
    let(:source) { described_class.create!(domain: "example.com", trust_level: :neutral) }

    it "matches exact domain" do
      expect(source.matches_url?("https://example.com/page")).to be true
    end

    it "matches subdomain" do
      expect(source.matches_url?("https://www.example.com/page")).to be true
    end

    it "does not match different domain" do
      expect(source.matches_url?("https://other.com/page")).to be false
    end

    it "handles invalid URLs gracefully" do
      expect(source.matches_url?("not a url")).to be false
    end
  end

  describe ".for_url" do
    before do
      described_class.create!(domain: "example.com", trust_level: :trusted)
      described_class.create!(domain: "api.example.com", trust_level: :always_prefer)
    end

    it "finds exact domain match" do
      source = described_class.for_url("https://example.com/page")
      expect(source.domain).to eq("example.com")
    end

    it "finds subdomain match" do
      source = described_class.for_url("https://api.example.com/endpoint")
      expect(source.domain).to eq("api.example.com")
    end

    it "returns nil for unknown domain" do
      expect(described_class.for_url("https://unknown.com/page")).to be_nil
    end

    it "handles invalid URLs gracefully" do
      expect(described_class.for_url("not a url")).to be_nil
    end
  end

  describe "#trust_score" do
    it "returns 5 for always_prefer" do
      source = described_class.new(domain: "test.com", trust_level: :always_prefer)
      expect(source.trust_score).to eq(5)
    end

    it "returns 4 for trusted" do
      source = described_class.new(domain: "test.com", trust_level: :trusted)
      expect(source.trust_score).to eq(4)
    end

    it "returns 3 for neutral" do
      source = described_class.new(domain: "test.com", trust_level: :neutral)
      expect(source.trust_score).to eq(3)
    end

    it "returns 2 for untrusted" do
      source = described_class.new(domain: "test.com", trust_level: :untrusted)
      expect(source.trust_score).to eq(2)
    end

    it "returns 1 for never_use" do
      source = described_class.new(domain: "test.com", trust_level: :never_use)
      expect(source.trust_score).to eq(1)
    end
  end

  describe "trust level helpers" do
    it "identifies preferred sources" do
      source = described_class.new(domain: "test.com", trust_level: :always_prefer)
      expect(source.preferred?).to be true
    end

    it "identifies trustworthy sources" do
      source = described_class.new(domain: "test.com", trust_level: :trusted)
      expect(source.trustworthy?).to be true
    end

    it "identifies sources to avoid" do
      source = described_class.new(domain: "test.com", trust_level: :untrusted)
      expect(source.avoid?).to be true
    end
  end
end
