# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Template, type: :model do
  fixtures :panda_cms_templates

  describe "associations" do
    it { should have_many(:pages).dependent(:restrict_with_error) }
    it { should have_many(:blocks).dependent(:restrict_with_error) }
    it { should have_many(:block_contents).through(:blocks) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:file_path) }
    it { should validate_uniqueness_of(:file_path) }

    context "file_path format" do
      it "allows valid layout paths where the file exists" do
        template = Panda::CMS::Template.new(
          name: "Test Template",
          file_path: "layouts/post"
        )
        expect(template).to be_valid
      end

      it "does not allow valid layout paths where the file does not exist" do
        template = Panda::CMS::Template.new(
          name: "Test Template",
          file_path: "layouts/page_not_here"
        )
        expect(template).to be_invalid
      end

      it "rejects invalid layout paths" do
        template = Panda::CMS::Template.new(
          name: "Test Template",
          file_path: "invalid/path"
        )
        expect(template).not_to be_valid
        expect(template.errors[:file_path]).to include("must be a valid layout file path")
      end
    end

    context "template file existence" do
      let(:template) do
        Panda::CMS::Template.new(
          name: "Test Template",
          file_path: "layouts/page"
        )
      end

      before do
        allow(File).to receive(:file?).and_return(false)
      end

      it "validates template file exists" do
        expect(template).not_to be_valid
        expect(template.errors[:file_path]).to include("must be an existing layout file path")
      end
    end
  end

  describe "scopes" do
    let!(:page_template) { panda_cms_templates(:page_template) }
    let!(:homepage_template) { panda_cms_templates(:homepage_template) }
    let!(:different_page_template) { panda_cms_templates(:different_page_template) }

    describe ".available" do
      it "returns templates with no max_uses limit" do
        available = described_class.available
        expect(available).to include(page_template)
      end

      it "returns templates with available capacity" do
        available = described_class.available
        # different_page_template has max_uses: 3, pages_count: 1
        expect(available).to include(different_page_template)
      end

      it "excludes templates that have reached their max_uses" do
        # Homepage template has max_uses: 1 and pages_count: 1 in fixtures
        # so it should be excluded from available
        available = described_class.available
        expect(available).not_to include(homepage_template)
      end
    end
  end

  describe "counter cache" do
    it "page model has counter_cache on belongs_to :template" do
      # Verify the association is set up correctly
      reflection = Panda::CMS::Page.reflect_on_association(:template)
      # Rails 7+ stores counter_cache as {active: true, column: "pages_count"}
      counter_cache_option = reflection.options[:counter_cache]
      if counter_cache_option.is_a?(Hash)
        expect(counter_cache_option[:column]).to eq("pages_count")
        expect(counter_cache_option[:active]).to be true
      else
        expect(counter_cache_option).to eq(:pages_count)
      end
    end
  end
end
