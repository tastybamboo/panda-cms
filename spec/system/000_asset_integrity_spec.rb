# frozen_string_literal: true

require "rails_helper"

# Constants defined outside RSpec block to avoid lint warnings
DUMMY_ROOT = Rails.root.join("spec/dummy")
ASSETS_DIR = DUMMY_ROOT.join("public/assets")
IMPORTMAP_FILE = DUMMY_ROOT.join("config/importmap.rb")

RSpec.describe "Asset & Importmap Integrity Check", order: :defined, system: true do
  # ------------------------------
  # 1. Importmap must exist
  # ------------------------------
  it "has a valid importmap.rb file" do
    expect(File.exist?(IMPORTMAP_FILE)).to be(true), <<~MSG
      ❌ spec/dummy/config/importmap.rb is missing.

      This prevents Rails from booting and will cause:
        - Capybara server startup failure
        - Cuprite/Ferrum websocket timeout
        - Rails asset helpers to crash during initialization

      Ensure importmap is copied / generated for the dummy app.
    MSG

    # Try loading the file to ensure it is syntactically valid
    expect { Importmap::Map.new.tap { |map| map.instance_eval(File.read(IMPORTMAP_FILE), IMPORTMAP_FILE.to_s) } }.not_to raise_error, <<~MSG
      ❌ spec/dummy/config/importmap.rb contains a syntax error or invalid Ruby.

      Fix the importmap before system tests run.
    MSG
  end

  # ------------------------------
  # 2. Validate importmap entries resolve to real files or URLs
  # ------------------------------
  it "all importmap entries resolve to existing paths or URLs" do
    map = Importmap::Map.new
    map.instance_eval(File.read(IMPORTMAP_FILE), IMPORTMAP_FILE.to_s) # populates map

    missing = []

    map.to_h.each do |logical_name, asset_path|
      next if asset_path.start_with?("https://", "http://") # external modules ok

      full_path = DUMMY_ROOT.join("vendor/javascript", asset_path)

      unless File.exist?(full_path)
        missing << "#{logical_name} (#{asset_path}) → #{full_path}"
      end
    end

    expect(missing).to be_empty, <<~MSG
      ❌ Importmap references files that do NOT exist in the dummy app:

      #{missing.map { |m| "  • #{m}" }.join("\n")}

      This will break Rails asset resolution and prevent Puma from booting.

      Fix by:
        - Ensuring all JS modules are copied into spec/dummy/vendor/javascript
        - Or updating the importmap paths defined in engine or dummy
    MSG
  end

  # ------------------------------
  # 3. Propshaft manifests must exist
  # ------------------------------
  it "has a Propshaft assets directory and manifest" do
    expect(Dir.exist?(ASSETS_DIR)).to be(true), <<~MSG
      ❌ spec/dummy/public/assets/ directory does not exist.

      System tests require compiled assets in the dummy app.

      Fix by copying compiled assets:
        cp -r public/assets spec/dummy/public/assets

      Or ensure your CI asset build step targets the dummy app.
    MSG

    manifest = Dir[ASSETS_DIR.join(".manifest.json").to_s].first
    expect(manifest).not_to be_nil, <<~MSG
      ❌ Propshaft manifest (.manifest.json) is missing in spec/dummy/public/assets.

      Without the manifest:
        - Propshaft cannot generate asset URLs
        - Rails helpers (javascript_include_tag, stylesheet_link_tag)
          will raise during initialization

      Ensure the asset pipeline is compiled correctly **for the dummy app**.
    MSG

    # Ensure manifest is JSON and loads
    expect { JSON.parse(File.read(manifest)) }.not_to raise_error, <<~MSG
      ❌ Propshaft .manifest.json is corrupt or unreadable.

      Rebuild assets for the dummy app.
    MSG
  end

  # ------------------------------
  # 4. Ensure the assets directory is not empty
  # ------------------------------
  it "assets directory contains files" do
    assets = begin
      Dir.children(ASSETS_DIR)
    rescue
      []
    end
    expect(assets).not_to be_empty, <<~MSG
      ❌ spec/dummy/public/assets is empty.

      This will make Rails server crash on boot because asset lookups fail.

      Fix by ensuring CI compiles assets *into the dummy app*, not the engine root.
    MSG
  end
end
