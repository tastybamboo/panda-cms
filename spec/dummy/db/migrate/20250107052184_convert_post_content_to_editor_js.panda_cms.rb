# This migration comes from panda_cms (originally 20241119214548)
class ConvertPostContentToEditorJs < ActiveRecord::Migration[7.1]
  def up
    Panda::CMS::Post.find_each do |post|
      next if post.post_content.blank?

      editor_content = {
        time: Time.current.to_i,
        version: "2.28.2",
        blocks: [
          {
            type: "paragraph",
            data: {
              text: post.post_content.to_plain_text
            }
          }
        ]
      }

      post.update_column(:content, editor_content)
    end
  end

  def down
    Panda::CMS::Post.find_each do |post|
      next if post.content.blank?

      # Extract plain text from EditorJS format
      plain_text = post.content["blocks"]
        &.map { |block| block["data"]["text"] }
        &.join("\n")

      post.update_column(:content, plain_text)
    end
  end
end
