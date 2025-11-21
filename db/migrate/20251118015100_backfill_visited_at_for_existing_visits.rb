# frozen_string_literal: true

class BackfillVisitedAtForExistingVisits < ActiveRecord::Migration[7.1]
  def up
    # Backfill visited_at from created_at for all existing visits where visited_at is NULL
    # This ensures historical visit data shows up in dashboard statistics
    execute <<-SQL
      UPDATE panda_cms_visits
      SET visited_at = created_at
      WHERE visited_at IS NULL
    SQL
  end

  def down
    # No need to reverse - visited_at values are still valid
  end
end
