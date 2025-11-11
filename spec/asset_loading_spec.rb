# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Asset Loading", type: :request do
  it "has compiled JavaScript assets available for testing", order: :first do
    # Check for panda-cms assets
    cms_asset_dir = Rails.root.join("public/panda-cms-assets")
    cms_js_assets = Dir.glob(cms_asset_dir.join("panda-cms-*.js"))

    expect(cms_js_assets).not_to be_empty, <<~ERROR

      ❌ CRITICAL: Compiled Panda CMS JavaScript assets not found!

      Looking in: #{cms_asset_dir}
      Expected: panda-cms-*.js files

      Compiled assets are required for system tests to run properly.
      Please run: bundle exec rake app:panda:cms:assets:compile

      For more information, see CLAUDE.md section on "JavaScript Asset Compilation Issues"
    ERROR

    # Verify the CMS asset has actual content
    cms_asset_path = cms_js_assets.first
    cms_content = File.read(cms_asset_path)
    expect(cms_content.length).to be > 1000, "CMS asset file exists but appears empty or too small (#{cms_content.length} bytes)"
    expect(cms_content).to include("pandaCmsLoaded"), "CMS asset missing required pandaCmsLoaded marker"
    expect(cms_content).to include("Stimulus"), "CMS asset missing Stimulus framework"

    puts "✅ Asset check passed: #{File.basename(cms_asset_path)} (#{cms_content.length} bytes)"
  end
end
