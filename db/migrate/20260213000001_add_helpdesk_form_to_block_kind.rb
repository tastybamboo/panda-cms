# frozen_string_literal: true

class AddHelpdeskFormToBlockKind < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TYPE panda_cms_block_kind ADD VALUE IF NOT EXISTS 'helpdesk_form'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
