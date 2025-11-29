FactoryBot.define do
  factory :user do
    uid { Faker::Internet.uuid }
    name { Faker::Name.name }
    sequence(:email) { |n| "test#{n}@example.com" }
    image { Faker::Internet.url }
  end
end
