# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Pro::ContentSyncLog, type: :model do
  let(:user) { create_admin_user }

  describe "validations" do
    it "requires sync_type" do
      log = described_class.new(user: user, status: :pending, items_synced: [])
      expect(log).not_to be_valid
      expect(log.errors[:sync_type]).to include("can't be blank")
    end

    it "requires status" do
      log = described_class.new(user: user, sync_type: :push, items_synced: [])
      expect(log).not_to be_valid
      expect(log.errors[:status]).to include("can't be blank")
    end

    it "requires user_id" do
      log = described_class.new(sync_type: :push, status: :pending, items_synced: [])
      expect(log).not_to be_valid
      expect(log.errors[:user_id]).to include("can't be blank")
    end

    it "requires items_synced" do
      log = described_class.new(user: user, sync_type: :push, status: :pending)
      expect(log).not_to be_valid
      expect(log.errors[:items_synced]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe "enums" do
    it "defines sync_type enum" do
      expect(described_class.sync_types.keys).to include("push", "pull")
    end

    it "defines status enum" do
      expect(described_class.statuses.keys).to include("pending", "in_progress", "completed", "failed", "rolled_back")
    end
  end

  describe "scopes" do
    before do
      described_class.create!(user: user, sync_type: :push, status: :completed, items_synced: [])
      described_class.create!(user: user, sync_type: :push, status: :failed, items_synced: [])
      described_class.create!(user: user, sync_type: :pull, status: :pending, items_synced: [])
    end

    it "filters successful syncs" do
      expect(described_class.successful.count).to eq(1)
    end

    it "filters failed syncs" do
      expect(described_class.failed_syncs.count).to eq(1)
    end

    it "filters pushes" do
      expect(described_class.pushes.count).to eq(2)
    end

    it "filters pulls" do
      expect(described_class.pulls.count).to eq(1)
    end
  end

  describe "#start!" do
    it "updates status to in_progress" do
      log = described_class.create!(user: user, sync_type: :push, status: :pending, items_synced: [])
      log.start!
      expect(log.status).to eq("in_progress")
      expect(log.started_at).to be_present
    end
  end

  describe "#complete!" do
    it "updates status to completed" do
      log = described_class.create!(user: user, sync_type: :push, status: :in_progress, items_synced: [])
      log.complete!(total_items: 10)
      expect(log.status).to eq("completed")
      expect(log.completed_at).to be_present
      expect(log.summary["total_items"]).to eq(10)
    end
  end

  describe "#fail!" do
    it "updates status to failed with error" do
      log = described_class.create!(user: user, sync_type: :push, status: :in_progress, items_synced: [])
      log.fail!(StandardError.new("Test error"))
      expect(log.status).to eq("failed")
      expect(log.error_log).to include("StandardError: Test error")
    end
  end

  describe "#duration" do
    it "calculates duration when completed" do
      log = described_class.create!(user: user, sync_type: :push, status: :pending, items_synced: [])
      log.update!(started_at: 1.hour.ago, completed_at: Time.current)
      expect(log.duration).to be_within(1).of(3600)
    end

    it "calculates duration for in-progress sync" do
      log = described_class.create!(user: user, sync_type: :push, status: :in_progress, items_synced: [])
      log.update!(started_at: 10.minutes.ago)
      expect(log.duration).to be_within(10).of(600)
    end
  end

  describe "#add_synced_item" do
    it "adds item to items_synced array" do
      log = described_class.create!(user: user, sync_type: :push, status: :in_progress, items_synced: [])
      log.add_synced_item("Page", "123", "created")
      expect(log.items_synced.length).to eq(1)
      expect(log.items_synced.first["type"]).to eq("Page")
      expect(log.items_synced.first["id"]).to eq("123")
      expect(log.items_synced.first["action"]).to eq("created")
    end
  end
end
