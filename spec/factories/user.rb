FactoryGirl.define do
  factory :user do
    username { FFaker::Name.name }
    email { FFaker::Internet.email }
    password { FFaker::Internet.password }
    trait :confirmed do
      confirmed_at { Time.zone.now }
    end
    trait :admin do
      admin true
    end
  end
end
