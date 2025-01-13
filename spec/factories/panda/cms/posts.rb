FactoryBot.define do
  factory :panda_cms_post, class: "Panda::CMS::Post", aliases: [:post] do
    sequence(:title) { |n| "Test Post #{n}" }
    sequence(:slug) { |n| "/#{Time.current.strftime("%Y/%m")}/test-post-#{n}" }
    status { "active" }
    published_at { Time.current }

    # Associate with an admin user for both user and author
    association :user, factory: :panda_cms_admin_user
    association :author, factory: :panda_cms_admin_user

    content do
      {
        time: Time.current.to_i * 1000,
        blocks: [
          {type: "header", data: {text: "Test Header", level: 2}},
          {type: "paragraph", data: {text: "Test content"}}
        ],
        version: "2.28.2"
      }
    end
  end
end
