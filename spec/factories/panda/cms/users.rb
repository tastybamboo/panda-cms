FactoryBot.define do
  factory :panda_cms_user, class: "Panda::CMS::User" do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:firstname) { |n| "User #{n}" }
    sequence(:lastname) { |n| "Lastname #{n}" }
    image_url { "/panda-cms-assets/panda-nav.png" }

    factory :panda_cms_admin_user do
      admin { true }
    end
  end
end
