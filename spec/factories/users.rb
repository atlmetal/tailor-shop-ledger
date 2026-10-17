FactoryBot.define do
  factory :user do
    shop
    name { "Ana Gómez" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
  end
end
