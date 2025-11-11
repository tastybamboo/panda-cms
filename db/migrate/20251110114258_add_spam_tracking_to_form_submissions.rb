class AddSpamTrackingToFormSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_form_submissions, :ip_address, :string
    add_column :panda_cms_form_submissions, :user_agent, :text
    add_index :panda_cms_form_submissions, :ip_address
  end
end
