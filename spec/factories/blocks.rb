FactoryBot.define do
  factory :block, class: "Panda::CMS::Block" do
    sequence(:name) { |n| "Block #{n}" }
    sequence(:key) { |n| "block_#{n}" }
    kind { "plain_text" }
    association :template, factory: :template
  end
end
