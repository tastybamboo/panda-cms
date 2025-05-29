require "rails_helper"

RSpec.describe Panda::CMS::User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:firstname) }
    it { should validate_presence_of(:lastname) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
  end

  describe "email" do
    it "downcases email before saving" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#is_admin?" do
    let(:user) { build(:user) }

    it "returns the admin status" do
      user.admin = true
      expect(user.is_admin?).to be true

      user.admin = false
      expect(user.is_admin?).to be false
    end
  end

  describe "#name" do
    let(:user) { build(:user, firstname: "John", lastname: "Doe") }

    it "returns the full name" do
      expect(user.name).to eq("John Doe")
    end
  end

  describe ".for_select_list" do
    it "returns users formatted for select list" do
      alice = create(:user, firstname: "Alice", lastname: "Smith")

      select_list = described_class.for_select_list
      expect(select_list).to be_an(Array)
      expect(select_list).to include(["Alice Smith", alice.id])
    end
  end
end
