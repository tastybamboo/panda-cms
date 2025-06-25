# frozen_string_literal: true

class AddDepthToPandaCMSMenus < ActiveRecord::Migration[7.2]
  def change
    add_column :panda_cms_menus, :depth, :integer, null: true, default: nil

    homepage = Panda::CMS::Page.find_by(path: "/")
    return unless homepage

    main_menu = Panda::CMS::Menu.find_by(start_page_id: homepage.id, kind: :auto)
    main_menu&.update(depth: 2)
  end
end
