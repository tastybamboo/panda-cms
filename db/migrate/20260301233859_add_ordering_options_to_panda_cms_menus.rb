# frozen_string_literal: true

class AddOrderingOptionsToPandaCmsMenus < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      ALTER TYPE panda_cms_menu_ordering ADD VALUE IF NOT EXISTS 'page_order';
    SQL
    execute <<-SQL
      ALTER TYPE panda_cms_menu_ordering ADD VALUE IF NOT EXISTS 'reverse_alphabetical';
    SQL
  end

  def down
    # PostgreSQL doesn't support removing enum values; recreate if needed
    raise ActiveRecord::IrreversibleMigration
  end
end
