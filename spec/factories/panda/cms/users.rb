FactoryBot.define do
  factory :panda_cms_user, class: "Panda::CMS::User", aliases: [:user] do
    sequence(:email) { |n| "#{firstname}_#{lastname}_#{n}@example.com" }
    firstname { "John" }
    lastname { "Doe" }
    image_url { "https://example.com/avatar.jpg" }
    admin { false }

    factory :panda_cms_admin_user, aliases: [:admin_user] do
      admin { true }
    end
  end
end
