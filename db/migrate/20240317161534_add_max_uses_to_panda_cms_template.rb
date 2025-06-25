# frozen_string_literal: true

class AddMaxUsesToPandaCMSTemplate < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_cms_templates, :max_uses, :integer, null: true, default: nil
    add_column :panda_cms_templates, :pages_count, :integer, default: 0
    Panda::CMS::Template.find_by(name: "Homepage")&.update(max_uses: 1)
  end
end
