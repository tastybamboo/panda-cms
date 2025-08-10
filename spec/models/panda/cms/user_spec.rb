# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::User, type: :model do
  fixtures :panda_cms_users
  
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "email" do
    it "downcases email before saving" do
      user = Panda::Core::User.create!(
        firstname: "Test",
        lastname: "User",
        email: "TEST@EXAMPLE.COM",
        admin: false
      )
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#admin?" do
    it "returns the admin status" do
      admin_user = panda_cms_users(:admin_user)
      regular_user = panda_cms_users(:regular_user)

      expect(admin_user.admin?).to be true
      expect(regular_user.admin?).to be false
    end
  end

  describe "#name" do
    it "returns the full name" do
      admin_user = panda_cms_users(:admin_user)

      expect(admin_user.name).to eq("Admin User")
    end
  end

  describe "#name=" do
    it "splits name into firstname and lastname" do
      user = Panda::Core::User.new
      user.name = "John Doe"
      expect(user.firstname).to eq("John")
      expect(user.lastname).to eq("Doe")
    end
  end
end
