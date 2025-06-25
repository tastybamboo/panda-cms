# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::User, type: :model do
  fixtures :panda_cms_users
  describe "validations" do
    it { should validate_presence_of(:firstname) }
    it { should validate_presence_of(:lastname) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe "email" do
    it "downcases email before saving" do
      user = Panda::CMS::User.create!(
        firstname: "Test",
        lastname: "User",
        email: "TEST@EXAMPLE.COM",
        admin: false
      )
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#is_admin?" do
    it "returns the admin status" do
      admin_user = panda_cms_users(:admin_user)
      regular_user = panda_cms_users(:regular_user)

      expect(admin_user.is_admin?).to be true
      expect(regular_user.is_admin?).to be false
    end
  end

  describe "#name" do
    it "returns the full name" do
      admin_user = panda_cms_users(:admin_user)

      expect(admin_user.name).to eq("Admin User")
    end
  end

  describe ".for_select_list" do
    it "returns users formatted for select list" do
      admin_user = panda_cms_users(:admin_user)

      select_list = described_class.for_select_list
      expect(select_list).to be_an(Array)
      expect(select_list).to include(["Admin User", admin_user.id])
    end
  end
end
