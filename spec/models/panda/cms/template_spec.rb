require "rails_helper"

RSpec.describe Panda::CMS::Template, type: :model do
  include_context "with standard pages"

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
        template = build(:template, file_path: "layouts/different_page")
        expect(template).to be_valid
      end

      it "does not allow valid layout paths where the file does not exist" do
        template = build(:template, file_path: "layouts/page_not_here")
        expect(template).to be_invalid
      end

      it "rejects invalid layout paths" do
        template = build(:template, file_path: "invalid/path")
        expect(template).not_to be_valid
        expect(template.errors[:file_path]).to include("must be a valid layout file path")
      end
    end

    context "template file existence" do
      let(:template) { build(:template) }

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
    let!(:page_template) { Panda::CMS::Template.find_by!(file_path: "layouts/page") }
    let!(:homepage_template) { Panda::CMS::Template.find_by!(file_path: "layouts/homepage") }
    let!(:different_page_template) { Panda::CMS::Template.find_or_create_by!(file_path: "layouts/different_page", name: "Different Page") }

    before do
      homepage_template.update!(max_uses: 1)
      different_page_template.update!(max_uses: 3, pages_count: 2)
    end

    describe ".available" do
      it "returns all templates with no max_uses or available capacity" do
        # Create a page using the homepage template
        create(:page, template: homepage_template, path: "/test")

        available = described_class.available
        expect(available).to include(page_template, different_page_template)
        expect(available).not_to include(homepage_template)
      end
    end
  end

  describe ".generate_missing_blocks" do
    # let(:homepage_template) { create(:template, file_path: "layouts/homepage") }
    # let(:homepage) { create(:page, template: homepage_template, parent: nil, path: "/") }

    let(:homepage) { Panda::CMS::Page.find_by!(path: "/") }
    let(:template) { create(:template, file_path: "layouts/different_page") }
    let(:template_content) do
      <<~ERB
        <%= render Panda::CMS::RichTextComponent.new(key: :content) %>
        <%= render Panda::CMS::TextComponent.new(key: :sidebar) %>
        <%= render Panda::CMS::MenuComponent.new(key: :navigation) %>
      ERB
    end

    before do
      allow(Dir).to receive(:glob).and_return(["app/views/layouts/different_page.html.erb"])
      allow(File).to receive(:open).and_return(StringIO.new(template_content))
    end

    it "creates blocks for components in templates" do
      expect {
        described_class.generate_missing_blocks
      }.to change(Panda::CMS::Block, :count).by(2) # Not counting MenuComponent
    end

    it "creates block_contents for existing pages" do
      page = create(:page, template: template, parent: homepage)
      described_class.generate_missing_blocks
      expect(page.block_contents.count).to eq(2)
    end
  end
end
