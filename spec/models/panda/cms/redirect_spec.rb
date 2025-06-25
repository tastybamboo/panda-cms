# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Redirect, type: :model do
  fixtures :panda_cms_pages

  let(:homepage) { panda_cms_pages(:homepage) }
  let(:about_page) { panda_cms_pages(:about_page) }

  describe "associations" do
    it "belongs to origin_page optionally" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0,
        origin_page: homepage
      )
      expect(redirect.origin_page).to eq(homepage)
    end

    it "belongs to destination_page optionally" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0,
        destination_page: about_page
      )
      expect(redirect.destination_page).to eq(about_page)
    end

    it "can exist without origin_page" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect.origin_page).to be_nil
      expect(redirect).to be_valid
    end

    it "can exist without destination_page" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect.destination_page).to be_nil
      expect(redirect).to be_valid
    end
  end

  describe "validations" do
    it "validates presence of status_code" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: nil
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:status_code]).to include("can't be blank")
    end

    it "validates presence of visits" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: nil
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:visits]).to include("can't be blank")
    end

    it "validates presence of origin_path" do
      redirect = Panda::CMS::Redirect.new(
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:origin_path]).to include("can't be blank")
    end

    it "validates presence of destination_path" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:destination_path]).to include("can't be blank")
    end

    it "validates origin_path format - must start with forward slash" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "invalid-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:origin_path]).to include("must start with a forward slash")
    end

    it "validates destination_path format - must start with forward slash" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "invalid-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).not_to be_valid
      expect(redirect.errors[:destination_path]).to include("must start with a forward slash")
    end

    it "accepts valid paths starting with forward slash" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).to be_valid
    end

    it "accepts complex valid paths" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old/complex/path?param=value",
        destination_path: "/new/complex/path#anchor",
        status_code: 302,
        visits: 5
      )
      expect(redirect).to be_valid
    end
  end

  describe "status codes" do
    it "accepts 301 status code" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).to be_valid
    end

    it "accepts 302 status code" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 302,
        visits: 0
      )
      expect(redirect).to be_valid
    end

    it "accepts other valid HTTP status codes" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 307,
        visits: 0
      )
      expect(redirect).to be_valid
    end
  end

  describe "visits tracking" do
    it "accepts zero visits" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 0
      )
      expect(redirect).to be_valid
    end

    it "accepts positive visit counts" do
      redirect = Panda::CMS::Redirect.new(
        origin_path: "/old-path",
        destination_path: "/new-path",
        status_code: 301,
        visits: 100
      )
      expect(redirect).to be_valid
    end
  end

  describe "table name" do
    it "uses the correct table name" do
      expect(described_class.table_name).to eq("panda_cms_redirects")
    end
  end

  describe "complete redirect scenarios" do
    it "creates a basic redirect without pages" do
      redirect = Panda::CMS::Redirect.create!(
        origin_path: "/blog/old-post",
        destination_path: "/blog/new-post",
        status_code: 301,
        visits: 0
      )

      expect(redirect).to be_persisted
      expect(redirect.origin_path).to eq("/blog/old-post")
      expect(redirect.destination_path).to eq("/blog/new-post")
      expect(redirect.status_code).to eq(301)
      expect(redirect.visits).to eq(0)
    end

    it "creates a redirect with associated pages" do
      redirect = Panda::CMS::Redirect.create!(
        origin_path: "/old-home",
        destination_path: "/",
        status_code: 301,
        visits: 10,
        origin_page: about_page,
        destination_page: homepage
      )

      expect(redirect).to be_persisted
      expect(redirect.origin_page).to eq(about_page)
      expect(redirect.destination_page).to eq(homepage)
    end
  end
end
