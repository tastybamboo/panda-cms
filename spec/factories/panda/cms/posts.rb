FactoryBot.define do
  factory :panda_cms_post, class: "Panda::CMS::Post", aliases: [:post] do
    sequence(:title) { |n| "Post Title #{n}" }
    sequence(:slug) { |n|
      now = Time.current
      "/#{now.year}/#{now.strftime("%m")}/post-#{n}"
    }
    status { "active" }
    published_at { Time.current }
    association :user, factory: :panda_cms_user
    association :author, factory: :panda_cms_user
    content do
      {
        "time" => Time.current.to_i,
        "blocks" => [
          {
            "type" => "header",
            "data" => {
              "text" => "Original Header",
              "level" => 2
            }
          },
          {
            "type" => "paragraph",
            "data" => {
              "text" => "Original content"
            }
          }
        ]
      }
    end
  end
end
