class AddCurrentThemeToPandaCMSUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_users, :current_theme, :string, default: 'default'
  end
end
