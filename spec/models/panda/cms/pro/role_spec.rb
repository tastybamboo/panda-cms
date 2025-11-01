# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Pro::Role, type: :model do
  describe "validations" do
    it "requires a name" do
      role = described_class.new(permissions: {})
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
    end

    it "requires unique name" do
      described_class.create!(name: "duplicate", permissions: {})
      role = described_class.new(name: "duplicate", permissions: {})
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("has already been taken")
    end

    it "requires permissions" do
      role = described_class.new(name: "test")
      expect(role).not_to be_valid
      expect(role.errors[:permissions]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "has many user_roles" do
      expect(described_class.reflect_on_association(:user_roles).macro).to eq(:has_many)
    end

    it "has many users through user_roles" do
      expect(described_class.reflect_on_association(:users).macro).to eq(:has_many)
      expect(described_class.reflect_on_association(:users).options[:through]).to eq(:user_roles)
    end
  end

  describe "scopes" do
    before do
      described_class.create!(name: "system_role_1", permissions: {}, system_role: true)
      described_class.create!(name: "custom_role_1", permissions: {}, system_role: false)
    end

    it "filters system roles" do
      expect(described_class.system_roles.count).to eq(1)
      expect(described_class.system_roles.first.name).to eq("system_role_1")
    end

    it "filters custom roles" do
      expect(described_class.custom_roles.count).to eq(1)
      expect(described_class.custom_roles.first.name).to eq("custom_role_1")
    end
  end

  describe "#can?" do
    let(:role) do
      described_class.create!(
        name: "test_role",
        permissions: {create_content: true, edit_content: false}
      )
    end

    it "returns true for granted permissions" do
      expect(role.can?(:create_content)).to be true
    end

    it "returns false for denied permissions" do
      expect(role.can?(:edit_content)).to be false
    end

    it "returns false for undefined permissions" do
      expect(role.can?(:undefined_permission)).to be false
    end

    it "accepts string permission names" do
      expect(role.can?("create_content")).to be true
    end
  end

  describe "default permissions" do
    it "defines admin permissions" do
      expect(described_class::DEFAULT_PERMISSIONS[described_class::ADMIN]).to be_a(Hash)
      expect(described_class::DEFAULT_PERMISSIONS[described_class::ADMIN][:manage_roles]).to be true
    end

    it "defines editor permissions" do
      expect(described_class::DEFAULT_PERMISSIONS[described_class::EDITOR]).to be_a(Hash)
      expect(described_class::DEFAULT_PERMISSIONS[described_class::EDITOR][:edit_content]).to be true
    end

    it "defines contributor permissions" do
      expect(described_class::DEFAULT_PERMISSIONS[described_class::CONTRIBUTOR]).to be_a(Hash)
      expect(described_class::DEFAULT_PERMISSIONS[described_class::CONTRIBUTOR][:manage_roles]).to be false
    end
  end
end
