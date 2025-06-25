# frozen_string_literal: true

class ResetCounterCacheOnPandaCMSTemplate < ActiveRecord::Migration[7.1]
  def change
    Panda::CMS::Template.find_each { |t| Panda::CMS::Template.reset_counters(t.id, :pages) }
  end
end
