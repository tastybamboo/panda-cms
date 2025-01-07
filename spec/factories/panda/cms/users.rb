FactoryBot.define do
  factory :panda_cms_user, class: "Panda::CMS::User", aliases: [:user] do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:firstname) { |n| "User #{n}" }
    sequence(:lastname) { |n| "Lastname #{n}" }
    image_url { "/panda-cms-assets/panda-nav.png" }

    factory :panda_cms_admin_user, aliases: [:admin_user] do
      admin { true }
      firstname { "Admin" }
      lastname { "User" }
    end
  end
end
