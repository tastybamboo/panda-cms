# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Admin::PostsHelper, type: :helper do
  describe "#editor_content_for" do
    let(:admin_user) { create_admin_user }

    context "with hash content" do
      let(:post) do
        Panda::CMS::Post.new(
          content: {"blocks" => [{"type" => "paragraph", "data" => {"text" => "Hello"}}]},
          user: admin_user,
          author: admin_user
        )
      end

      it "returns base64 encoded JSON by default" do
        result = helper.editor_content_for(post)
        decoded = Base64.strict_decode64(result)
        parsed = JSON.parse(decoded)
        expect(parsed["blocks"].first["type"]).to eq("paragraph")
      end

      it "returns raw JSON when encode: false" do
        result = helper.editor_content_for(post, nil, encode: false)
        parsed = JSON.parse(result)
        expect(parsed["blocks"].first["type"]).to eq("paragraph")
      end

      it "returns valid JSON (not Ruby hash inspect) when encode: false" do
        result = helper.editor_content_for(post, nil, encode: false)
        # Must not contain Ruby hash rocket syntax
        expect(result).not_to include("=>")
        # Must be valid JSON
        expect { JSON.parse(result) }.not_to raise_error
      end
    end

    context "with blank content" do
      let(:post) do
        Panda::CMS::Post.new(
          content: {},
          user: admin_user,
          author: admin_user
        )
      end

      it "returns empty blocks structure when encode: false" do
        result = helper.editor_content_for(post, nil, encode: false)
        parsed = JSON.parse(result)
        expect(parsed["blocks"]).to eq([])
      end
    end

    context "with preserved content (JSON string)" do
      let(:post) do
        Panda::CMS::Post.new(
          content: {},
          user: admin_user,
          author: admin_user
        )
      end
      let(:preserved) { '{"blocks":[{"type":"header","data":{"text":"Preserved","level":2}}]}' }

      it "uses preserved content over post content" do
        result = helper.editor_content_for(post, preserved, encode: false)
        parsed = JSON.parse(result)
        expect(parsed["blocks"].first["type"]).to eq("header")
      end
    end
  end
end
