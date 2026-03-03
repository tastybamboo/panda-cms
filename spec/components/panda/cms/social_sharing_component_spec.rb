# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::SocialSharingComponent, type: :component do
  let(:title) { "Test Post Title" }
  let(:url) { "https://example.com/blog/test-post" }

  before do
    # Clear cache before each test
    Rails.cache.delete("panda_cms:social_sharing:enabled_networks")
  end

  describe "#render?" do
    it "returns false when no networks are enabled" do
      Panda::CMS::SocialSharingNetwork.register_all

      component = described_class.new(title: title, url: url)
      expect(component.render?).to be false
    end

    it "returns true when networks are enabled" do
      Panda::CMS::SocialSharingNetwork.register_all
      Panda::CMS::SocialSharingNetwork.find_by(key: "facebook").update!(enabled: true)

      component = described_class.new(title: title, url: url)
      expect(component.render?).to be true
    end
  end

  describe "rendering" do
    before do
      Panda::CMS::SocialSharingNetwork.register_all
      Panda::CMS::SocialSharingNetwork.find_by(key: "facebook").update!(enabled: true)
      Panda::CMS::SocialSharingNetwork.find_by(key: "x").update!(enabled: true)
      Panda::CMS::SocialSharingNetwork.find_by(key: "copy_link").update!(enabled: true)
    end

    it "renders a nav element with aria-label" do
      output = render_inline(described_class.new(title: title, url: url, label: "Share this"))
      expect(output.css("nav[aria-label='Share this']")).to be_present
    end

    it "renders enabled networks as links" do
      output = render_inline(described_class.new(title: title, url: url))
      links = output.css("a[target='_blank']")
      expect(links.length).to eq(2) # facebook and x (not copy_link)
    end

    it "renders share links with correct href" do
      output = render_inline(described_class.new(title: title, url: url))
      facebook_link = output.css("a").find { |a| a.text.include?("Facebook") }
      expect(facebook_link["href"]).to include("facebook.com/sharer/sharer.php")
      expect(facebook_link["href"]).to include(ERB::Util.url_encode(url))
    end

    it "renders links with noopener noreferrer" do
      output = render_inline(described_class.new(title: title, url: url))
      links = output.css("a[target='_blank']")
      links.each do |link|
        expect(link["rel"]).to eq("noopener noreferrer")
      end
    end

    it "renders network names as visible text" do
      output = render_inline(described_class.new(title: title, url: url))
      expect(output.text).to include("Facebook")
      expect(output.text).to include("X")
      expect(output.text).to include("Copy Link")
    end

    it "renders brand colours as inline styles" do
      output = render_inline(described_class.new(title: title, url: url))
      facebook_link = output.css("a").find { |a| a.text.include?("Facebook") }
      expect(facebook_link["style"]).to include("#1877F2")
    end

    it "renders copy link as a button with clipboard controller" do
      output = render_inline(described_class.new(title: title, url: url))
      copy_button = output.css("button[data-controller='clipboard']").first

      expect(copy_button).to be_present
      expect(copy_button["data-clipboard-secret-value"]).to eq(url)
      expect(copy_button["data-action"]).to eq("click->clipboard#copy")
    end

    it "renders the label text" do
      output = render_inline(described_class.new(title: title, url: url, label: "Share this article"))
      expect(output.text).to include("Share this article")
    end

    it "does not render disabled networks" do
      output = render_inline(described_class.new(title: title, url: url))
      expect(output.text).not_to include("LinkedIn")
      expect(output.text).not_to include("WhatsApp")
    end
  end
end
