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
      let(:template) {
        Panda::CMS::Template.new(
          name: "Test Template",
          file_path: "layouts/page"
        )
      }

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
      it "returns all templates with no max_uses or available capacity" do
        available = described_class.available
        expect(available).to include(page_template)
        expect(available).to include(different_page_template)
        # Homepage template has max_uses: 1, so availability depends on usage
      end
    end
  end
end
