# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::ApplicationHelper, type: :helper do
  after do
    Panda::CMS::Features.reset!
  end

  describe "#panda_cms_collection_items" do
    it "raises when the collections feature is not available" do
      expect do
        helper.panda_cms_collection_items("trustees")
      end.to raise_error(Panda::CMS::Features::MissingFeatureError)
    end

    it "delegates to Panda::CMS::Collections when the feature is enabled" do
      Panda::CMS::Features.register(:collections, provider: "stub")

      stub_const("Panda::CMS::Collections", Module.new do
        def self.items(slug, include_unpublished: false)
          ["collection:#{slug}:#{include_unpublished}"]
        end
      end)

      result = helper.panda_cms_collection_items("trustees", include_unpublished: true)
      expect(result).to eq(["collection:trustees:true"])
    end
  end
end
