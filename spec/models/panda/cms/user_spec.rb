# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::User, type: :model do
  describe "validations" do
    subject {
      Panda::Core::User.new(
        email: "test@example.com",
        name: "Test User",
        is_admin: false
      )
    }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "email" do
    it "downcases email before saving" do
      user = Panda::Core::User.create!(
        name: "Test User",
        email: "TEST@EXAMPLE.COM",
        is_admin: false
      )
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#admin?" do
    it "returns the admin status" do
      # binding.irb
      admin = create_admin_user
      regular = create_regular_user

      expect(admin.admin?).to be true
      expect(regular.admin?).to be false
    end
  end

  describe "#name" do
    it "returns the full name" do
      admin = create_admin_user

      expect(admin.name).to eq("Admin User")
    end
  end
end
