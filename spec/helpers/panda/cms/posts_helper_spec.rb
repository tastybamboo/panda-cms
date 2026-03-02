# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::PostsHelper, type: :helper do
  let(:admin_user) { create_admin_user }

  describe "#display_post_path" do
    it "unescapes the post slug for display" do
      post = Panda::CMS::Post.new(slug: "/2024/01/hello-world")
      expect(helper.display_post_path(post)).to eq("/2024/01/hello-world")
    end

    it "decodes percent-encoded characters in slugs" do
      post = Panda::CMS::Post.new(slug: "/2024/01/hello%20world")
      expect(helper.display_post_path(post)).to eq("/2024/01/hello world")
    end
  end

  describe "#posts_months_menu" do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = original_cache
    end

    context "when there are no published posts" do
      it "returns an empty array" do
        expect(helper.posts_months_menu).to eq([])
      end
    end

    context "when there are published posts" do
      let!(:post_jan) do
        Panda::CMS::Post.create!(
          title: "January Post",
          slug: "/2024/01/january-post",
          user: admin_user,
          author: admin_user,
          status: "published",
          published_at: Time.zone.parse("2024-01-15 12:00:00")
        )
      end

      let!(:post_feb) do
        Panda::CMS::Post.create!(
          title: "February Post",
          slug: "/2024/02/february-post",
          user: admin_user,
          author: admin_user,
          status: "published",
          published_at: Time.zone.parse("2024-02-20 12:00:00")
        )
      end

      let!(:draft_post) do
        Panda::CMS::Post.create!(
          title: "Draft Post",
          slug: "/draft-post",
          user: admin_user,
          author: admin_user,
          status: "hidden"
        )
      end

      it "returns entries for each month with published posts" do
        result = helper.posts_months_menu
        expect(result.length).to eq(2)
      end

      it "returns months in descending order" do
        result = helper.posts_months_menu
        years_months = result.map { |r| [r[:year], r[:month]] }
        expect(years_months).to eq([["2024", "02"], ["2024", "01"]])
      end

      it "includes year, month, month_name, and post_count keys" do
        result = helper.posts_months_menu
        entry = result.first

        expect(entry).to have_key(:year)
        expect(entry).to have_key(:month)
        expect(entry).to have_key(:month_name)
        expect(entry).to have_key(:post_count)
      end

      it "returns the correct year and zero-padded month" do
        result = helper.posts_months_menu
        feb_entry = result.find { |r| r[:month] == "02" }

        expect(feb_entry[:year]).to eq("2024")
        expect(feb_entry[:month]).to eq("02")
      end

      it "returns a human-readable month_name" do
        result = helper.posts_months_menu
        feb_entry = result.find { |r| r[:month] == "02" }

        expect(feb_entry[:month_name]).to eq("February 2024")
      end

      it "uses the month_date SQL alias to avoid collision with Post#month" do
        raw = Panda::CMS::Post
          .where(status: :published)
          .select(
            Arel.sql("DATE_TRUNC('month', published_at) as month_date"),
            Arel.sql("COUNT(*) as post_count")
          )
          .group(Arel.sql("DATE_TRUNC('month', published_at)"))
          .reorder(Arel.sql("DATE_TRUNC('month', published_at) DESC"))
          .first

        expect(raw).to respond_to(:month_date)
        expect(raw.month_date).to be_a(Time)
      end

      it "counts only published posts per month" do
        result = helper.posts_months_menu
        jan_entry = result.find { |r| r[:month] == "01" }

        expect(jan_entry[:post_count]).to eq(1)
      end

      it "does not include unpublished posts in the menu" do
        result = helper.posts_months_menu
        expect(result.map { |r| r[:post_count] }.sum).to eq(2)
      end

      it "caches the result" do
        first_result = helper.posts_months_menu
        second_result = helper.posts_months_menu

        expect(second_result).to eq(first_result)
        expect(Rails.cache.exist?("panda_cms_posts_months_menu")).to be true
      end

      context "with multiple posts in the same month" do
        let!(:post_jan2) do
          Panda::CMS::Post.create!(
            title: "Another January Post",
            slug: "/2024/01/another-january-post",
            user: admin_user,
            author: admin_user,
            status: "published",
            published_at: Time.zone.parse("2024-01-25 12:00:00")
          )
        end

        it "groups posts by month and sums the count" do
          result = helper.posts_months_menu
          jan_entry = result.find { |r| r[:month] == "01" }

          expect(jan_entry[:post_count]).to eq(2)
        end
      end
    end
  end
end
