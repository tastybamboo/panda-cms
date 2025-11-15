# frozen_string_literal: true

RSpec.describe "Asset Preflight", :system do
  it "verifies dummy assets exist" do
    assets_root = Rails.root.join("public/assets")

    expect(assets_root).to exist
    expect(assets_root.join(".manifest.json")).to exist
    expect(assets_root.join("importmap.json")).to exist

    manifest = JSON.parse(File.read(assets_root.join(".manifest.json")))
    expect(manifest).not_to be_empty
  end
end
