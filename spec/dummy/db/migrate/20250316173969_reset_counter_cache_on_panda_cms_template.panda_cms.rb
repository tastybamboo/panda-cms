# This migration comes from panda_cms (originally 20240317163053)
class ResetCounterCacheOnPandaCMSTemplate < ActiveRecord::Migration[7.1]
  def change
    Panda::CMS::Template.find_each { |t| Panda::CMS::Template.reset_counters(t.id, :pages) }
  end
end
