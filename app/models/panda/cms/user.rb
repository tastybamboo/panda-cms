module Panda
  module CMS
    class User < ApplicationRecord
      validates :firstname, presence: true
      validates :lastname, presence: true
      validates :email, presence: true, uniqueness: true

      before_save :downcase_email

      scope :admin, -> { where(admin: true) }

      def is_admin?
        admin
      end

      def name
        "#{firstname} #{lastname}"
      end

      def self.for_select_list(scope = :all, order = {firstname: :asc, lastname: :asc})
        Panda::CMS::User.send(scope).order(order).map { |u| [u.name, u.id] }
      end

      private

      def downcase_email
        self.email = email.to_s.downcase
      end
    end
  end
end
