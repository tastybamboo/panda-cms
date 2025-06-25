# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Zeitwerk Loading" do
  describe "BulkEditor" do
    it "loads correctly" do
      # Check if the class is defined
      expect(defined?(Panda::CMS::BulkEditor)).to eq("constant"), "BulkEditor class should be defined"

      # Try to instantiate it
      expect { Panda::CMS::BulkEditor }.not_to raise_error

      # Verify the class is loaded from the correct file
      expected_file = File.expand_path("../lib/panda/cms/bulk_editor.rb", __dir__)
      actual_file = Panda::CMS::BulkEditor.method(:export).source_location.first
      expect(actual_file).to eq(expected_file), "BulkEditor should be loaded from the correct file"
    end

    it "survives eager loading" do
      # Force eager loading
      Rails.application.eager_load!

      # Verify BulkEditor is still accessible
      expect(defined?(Panda::CMS::BulkEditor)).to eq("constant"), "BulkEditor should survive eager loading"
    end
  end
end
