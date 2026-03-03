# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::PostCategory, type: :model do
  let(:admin_user) { create_admin_user }

  describe "validations" do
    it "requires a name" do
      category = Panda::CMS::PostCategory.new(name: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name" do
      Panda::CMS::PostCategory.create!(name: "Unique Category")
      duplicate = Panda::CMS::PostCategory.new(name: "Unique Category")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "requires a unique slug" do
      Panda::CMS::PostCategory.create!(name: "First", slug: "test-slug")
      duplicate = Panda::CMS::PostCategory.new(name: "Second", slug: "test-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "validates slug format" do
      category = Panda::CMS::PostCategory.new(name: "Test", slug: "Invalid Slug!")
      expect(category).not_to be_valid
      expect(category.errors[:slug]).to include("must contain only lowercase letters, numbers, and hyphens")
    end

    it "accepts valid slug formats" do
      category = Panda::CMS::PostCategory.new(name: "Test", slug: "valid-slug-123")
      expect(category).to be_valid
    end
  end

  describe "slug auto-generation" do
    it "generates a slug from the name when slug is blank" do
      category = Panda::CMS::PostCategory.new(name: "My Category")
      category.valid?
      expect(category.slug).to eq("my-category")
    end

    it "does not overwrite an existing slug" do
      category = Panda::CMS::PostCategory.new(name: "My Category", slug: "custom-slug")
      category.valid?
      expect(category.slug).to eq("custom-slug")
    end
  end

  describe "#deletable?" do
    it "returns false for the general category" do
      general = panda_cms_post_categories(:general)
      expect(general.deletable?).to be false
    end

    it "returns true for other categories" do
      news = panda_cms_post_categories(:news)
      expect(news.deletable?).to be true
    end
  end

  describe "dependent: :restrict_with_error" do
    it "prevents deletion of a category with posts" do
      category = Panda::CMS::PostCategory.create!(name: "Has Posts", slug: "has-posts")
      Panda::CMS::Post.create!(
        title: "Restrict Post",
        slug: "/restrict-post",
        user: admin_user,
        author: admin_user,
        post_category: category,
        status: "published"
      )

      expect(category.destroy).to be false
      expect(category.errors[:base]).to include("Cannot delete record because dependent posts exist")
    end
  end

  describe ".ordered" do
    it "orders categories by name" do
      categories = Panda::CMS::PostCategory.ordered
      expect(categories.map(&:name)).to eq(categories.map(&:name).sort)
    end
  end
end
