#!/usr/bin/env ruby

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
