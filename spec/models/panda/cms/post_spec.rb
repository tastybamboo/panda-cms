# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::CMS::Post, type: :model do
  fixtures :panda_core_users
  describe "editor content", :editorjs do
    let(:post) do
      Panda::CMS::Post.create!(
        title: "Test Post",
        slug: "/test-post",
        user: panda_core_users(:admin_user),
        author: panda_core_users(:admin_user),
        status: "active"
      )
    end

    it "stores and caches EditorJS content" do
      editor_content = {
        "source" => "editorJS",
        "time" => Time.current.to_i,
        "blocks" => [
          {
            "type" => "paragraph",
            "data" => {
              "text" => "Test content"
            }
          }
        ]
      }

      post.content = editor_content
      post.save!
      post.reload

      expect(post.content).to eq(editor_content)
      expect(post.cached_content).to include("<p>Test content</p>")
    end
  end
end
