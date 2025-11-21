# frozen_string_literal: true

class AddIndexToVisitedAtOnPandaCMSVisits < ActiveRecord::Migration[7.1]
  def change
    add_index :panda_cms_visits, :visited_at
  end
end
