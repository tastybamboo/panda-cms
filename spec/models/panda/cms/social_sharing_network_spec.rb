# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::SocialSharingNetwork, type: :model do
  describe "REGISTRY" do
    it "contains all 9 networks" do
      expect(described_class::REGISTRY.keys).to eq(
        %w[facebook x linkedin whatsapp bluesky mastodon threads email copy_link]
      )
    end

    it "has required metadata keys for each network" do
      described_class::REGISTRY.each do |key, meta|
        expect(meta).to have_key(:name), "#{key} missing :name"
        expect(meta).to have_key(:icon), "#{key} missing :icon"
        expect(meta).to have_key(:color), "#{key} missing :color"
        expect(meta).to have_key(:share_url), "#{key} missing :share_url"
      end
    end

    it "has share_url for all networks except copy_link" do
      described_class::REGISTRY.each do |key, meta|
        if key == "copy_link"
          expect(meta[:share_url]).to be_nil
        else
          expect(meta[:share_url]).to be_present, "#{key} missing share_url"
        end
      end
    end
  end

  describe "table name" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("panda_cms_social_sharing_networks")
    end
  end

  describe "validations" do
    it "validates presence of key" do
      network = described_class.new(key: nil, position: 0)
      expect(network).not_to be_valid
      expect(network.errors[:key]).to include("can't be blank")
    end

    it "validates uniqueness of key" do
      described_class.create!(key: "facebook", position: 0)
      duplicate = described_class.new(key: "facebook", position: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to include("has already been taken")
    end

    it "validates key is in REGISTRY" do
      network = described_class.new(key: "invalid_network", position: 0)
      expect(network).not_to be_valid
      expect(network.errors[:key]).to include("is not included in the list")
    end

    it "validates presence of position" do
      network = described_class.new(key: "facebook", position: nil)
      expect(network).not_to be_valid
      expect(network.errors[:position]).to include("can't be blank")
    end
  end

  describe ".register_all" do
    it "creates all networks from REGISTRY" do
      expect {
        described_class.register_all
      }.to change(described_class, :count).by(9)
    end

    it "is idempotent" do
      described_class.register_all
      expect {
        described_class.register_all
      }.not_to change(described_class, :count)
    end

    it "preserves existing enabled state" do
      described_class.register_all
      described_class.find_by(key: "facebook").update!(enabled: true)

      described_class.register_all
      expect(described_class.find_by(key: "facebook").enabled).to be true
    end

    it "sets position based on REGISTRY order" do
      described_class.register_all
      facebook = described_class.find_by(key: "facebook")
      copy_link = described_class.find_by(key: "copy_link")

      expect(facebook.position).to eq(0)
      expect(copy_link.position).to eq(8)
    end
  end

  describe "scopes" do
    before { described_class.register_all }

    describe ".enabled" do
      it "returns only enabled networks ordered by position" do
        described_class.find_by(key: "x").update!(enabled: true)
        described_class.find_by(key: "whatsapp").update!(enabled: true)

        enabled = described_class.enabled
        expect(enabled.map(&:key)).to eq(%w[x whatsapp])
      end

      it "returns empty when none enabled" do
        expect(described_class.enabled).to be_empty
      end
    end

    describe ".ordered" do
      it "returns networks ordered by position" do
        ordered = described_class.ordered
        expect(ordered.first.key).to eq("facebook")
        expect(ordered.last.key).to eq("copy_link")
      end
    end
  end

  describe "instance methods" do
    let(:network) do
      described_class.create!(key: "facebook", position: 0)
    end

    describe "#metadata" do
      it "returns the REGISTRY entry" do
        expect(network.metadata[:name]).to eq("Facebook")
        expect(network.metadata[:icon]).to eq("fab fa-facebook-f")
      end
    end

    describe "#display_name" do
      it "returns the human name" do
        expect(network.display_name).to eq("Facebook")
      end
    end

    describe "#icon" do
      it "returns the icon class" do
        expect(network.icon).to eq("fab fa-facebook-f")
      end
    end

    describe "#color" do
      it "returns the brand colour" do
        expect(network.color).to eq("#1877F2")
      end
    end

    describe "#copy_link?" do
      it "returns true for copy_link" do
        copy = described_class.create!(key: "copy_link", position: 8)
        expect(copy.copy_link?).to be true
      end

      it "returns false for other networks" do
        expect(network.copy_link?).to be false
      end
    end

    describe "#build_share_url" do
      it "builds URL with encoded title and url" do
        result = network.build_share_url(
          title: "Hello World",
          url: "https://example.com/post"
        )
        expect(result).to include("facebook.com/sharer/sharer.php")
        expect(result).to include("https%3A%2F%2Fexample.com%2Fpost")
      end

      it "handles special characters in title" do
        x_network = described_class.create!(key: "x", position: 1)
        result = x_network.build_share_url(
          title: "Test & <Script>",
          url: "https://example.com"
        )
        expect(result).to include("Test%20%26%20%3CScript%3E")
      end

      it "returns nil for copy_link" do
        copy = described_class.create!(key: "copy_link", position: 8)
        result = copy.build_share_url(title: "Test", url: "https://example.com")
        expect(result).to be_nil
      end

      it "builds mailto URL for email" do
        email = described_class.create!(key: "email", position: 7)
        result = email.build_share_url(
          title: "My Post",
          url: "https://example.com/post"
        )
        expect(result).to start_with("mailto:?subject=")
        expect(result).to include("My%20Post")
      end
    end
  end
end
