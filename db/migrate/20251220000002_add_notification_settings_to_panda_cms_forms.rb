# frozen_string_literal: true

class AddNotificationSettingsToPandaCMSForms < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_cms_forms, :notification_emails, :text
    add_column :panda_cms_forms, :notification_subject, :string
    add_column :panda_cms_forms, :send_confirmation, :boolean, default: false
    add_column :panda_cms_forms, :confirmation_subject, :string
    add_column :panda_cms_forms, :confirmation_body, :text
    add_column :panda_cms_forms, :confirmation_email_field, :string
    add_column :panda_cms_forms, :success_message, :text
    add_column :panda_cms_forms, :status, :string, default: "active"
    add_column :panda_cms_forms, :description, :text
  end
end
