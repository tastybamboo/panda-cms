# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Pro::Versionable, type: :model do
  let(:user) { create_admin_user }
  let(:post) do
    post = panda_cms_posts(:first_post)
    post.update!(user: user, author: user)
    post
  end

  describe "associations" do
    it "adds content_versions association" do
      expect(post).to respond_to(:content_versions)
      expect(post.content_versions).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "adds content_suggestions association" do
      expect(post).to respond_to(:content_suggestions)
    end

    it "adds content_comments association" do
      expect(post).to respond_to(:content_comments)
    end
  end

  describe "#create_version!" do
    it "creates a new version" do
      expect {
        post.create_version!(user: user, change_summary: "Test version")
      }.to change { post.content_versions.count }.by(1)
    end

    it "stores content in version" do
      version = post.create_version!(user: user, change_summary: "Test version")
      expect(version.content).to be_present
    end

    it "assigns sequential version numbers" do
      v1 = post.create_version!(user: user, change_summary: "Version 1")
      v2 = post.create_version!(user: user, change_summary: "Version 2")
      expect(v1.version_number).to eq(1)
      expect(v2.version_number).to eq(2)
    end

    it "defaults source to manual" do
      version = post.create_version!(user: user)
      expect(version.source).to eq("manual")
    end

    it "accepts custom source" do
      version = post.create_version!(user: user, source: "ai_generated")
      expect(version.source).to eq("ai_generated")
    end
  end

  describe "#latest_version" do
    it "returns most recent version" do
      v1 = post.create_version!(user: user, change_summary: "Version 1")
      v2 = post.create_version!(user: user, change_summary: "Version 2")
      expect(post.latest_version).to eq(v2)
    end

    it "returns nil when no versions exist" do
      expect(post.latest_version).to be_nil
    end
  end

  describe "#version" do
    it "finds version by number" do
      v1 = post.create_version!(user: user, change_summary: "Version 1")
      post.create_version!(user: user, change_summary: "Version 2")
      expect(post.version(1)).to eq(v1)
    end

    it "returns nil for non-existent version" do
      expect(post.version(999)).to be_nil
    end
  end

  describe "#restore_version!" do
    before do
      post.update!(title: "Original Title")
      post.create_version!(user: user, change_summary: "Original version")
      post.update!(title: "Modified Title")
      post.create_version!(user: user, change_summary: "Modified version")
    end

    it "restores content from specified version" do
      post.restore_version!(1, user: user)
      expect(post.reload.title).to eq("Original Title")
    end

    it "creates a new version after restore" do
      expect {
        post.restore_version!(1, user: user)
      }.to change { post.content_versions.count }.by(1)
    end

    it "marks restore in change summary" do
      post.restore_version!(1, user: user)
      expect(post.latest_version.change_summary).to include("Restored to version 1")
    end

    it "returns false for non-existent version" do
      expect(post.restore_version!(999, user: user)).to be false
    end
  end

  describe "#contributors" do
    it "returns users who created versions" do
      post.create_version!(user: user, change_summary: "Test")
      expect(post.contributors).to include(user)
    end
  end

  describe "#contributors_count" do
    it "counts unique contributors" do
      post.create_version!(user: user, change_summary: "Version 1")
      post.create_version!(user: user, change_summary: "Version 2")
      expect(post.contributors_count).to eq(1)
    end
  end

  describe "#pending_suggestions" do
    it "returns suggestions awaiting review" do
      suggestion = post.content_suggestions.create!(
        user: user,
        suggestion_type: :edit,
        status: :pending,
        content: {text: "New content"}
      )
      expect(post.pending_suggestions).to include(suggestion)
    end
  end

  describe "#unresolved_comments" do
    it "returns comments not yet resolved" do
      comment = post.content_comments.create!(
        user: user,
        content: "Test comment",
        resolved: false
      )
      expect(post.unresolved_comments).to include(comment)
    end
  end

  describe "#diff_with_version" do
    before do
      post.update!(title: "Version 1")
      post.create_version!(user: user, change_summary: "V1")
      post.update!(title: "Version 2")
      post.create_version!(user: user, change_summary: "V2")
    end

    it "returns diff information" do
      diff = post.diff_with_version(1)
      expect(diff).to be_a(Hash)
      expect(diff).to have_key(:current_content)
      expect(diff).to have_key(:version_content)
      expect(diff).to have_key(:version_number)
      expect(diff).to have_key(:changes_since)
    end

    it "counts changes since version" do
      diff = post.diff_with_version(1)
      expect(diff[:changes_since]).to eq(1)
    end
  end
end
