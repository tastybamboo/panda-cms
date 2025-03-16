# This migration comes from panda_core (originally 20250121012334)
module Panda
  module Core
    class EnableHstore < ActiveRecord::Migration[8.0]
      def change
        enable_extension :hstore
      end
    end
  end
end
