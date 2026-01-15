# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::SanctuaryDemo do
  describe ".generate!" do
    it "creates the demo site successfully" do
      expect {
        demo = described_class.generate!

        # Verify users were created
        expect(demo.users.count).to eq(3)
        expect(demo.users[:admin]).to be_persisted
        expect(demo.users[:admin].admin).to be true

        # Verify templates were created
        expect(demo.templates.count).to be >= 5
        expect(demo.templates[:sanctuary_homepage]).to be_persisted

        # Verify pages were created
        expect(demo.pages.count).to be >= 20
        expect(demo.pages[:home]).to be_persisted
        expect(demo.pages[:home].path).to eq("/")

        # Verify menus were created
        expect(demo.menus.count).to eq(2)
        expect(demo.menus[:main]).to be_persisted
        expect(demo.menus[:footer]).to be_persisted

        # Verify forms were created
        expect(demo.forms.count).to eq(3)
        expect(demo.forms[:contact]).to be_persisted

        # Verify posts were created
        expect(demo.posts.count).to be >= 5
        expect(demo.posts.first.user).to be_present
      }.to change(Panda::Core::User, :count).by(3)
        .and change(Panda::CMS::Template, :count).by_at_least(5)
        .and change(Panda::CMS::Page, :count).by_at_least(20)
        .and change(Panda::CMS::Post, :count).by_at_least(5)
    end

    it "is idempotent (can be run multiple times)" do
      # Run once
      described_class.generate!

      # Run again - should not create duplicates
      expect {
        demo = described_class.generate!
        expect(demo.users[:admin]).to be_persisted
        expect(demo.pages[:home]).to be_persisted
      }.not_to change(Panda::Core::User, :count)
    end

    it "creates blocks for template components" do
      demo = described_class.generate!

      # Homepage should have blocks for its editable components
      homepage_template = demo.templates[:sanctuary_homepage]
      expect(homepage_template.blocks.count).to be >= 4

      # Verify specific block keys exist
      block_keys = homepage_template.blocks.pluck(:key)
      expect(block_keys).to include("hero_title")
      expect(block_keys).to include("main_content")
    end

    it "creates block contents for pages" do
      demo = described_class.generate!

      homepage = demo.pages[:home]
      expect(homepage.block_contents.count).to be >= 4

      # Check that content was populated
      hero_block = homepage.block_contents.joins(:block).find_by(panda_cms_blocks: {key: "hero_title"})
      expect(hero_block&.content).to be_present
    end

    it "creates redirects for common paths" do
      described_class.generate!

      expect(Panda::CMS::Redirect.find_by(origin_path: "/pandas")).to be_present
      expect(Panda::CMS::Redirect.find_by(origin_path: "/contact")).to be_present
    end
  end
end
