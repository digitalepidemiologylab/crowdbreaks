FactoryBot.define do
  factory :user do
    username { FFaker::Name.name }
    email { FFaker::Internet.email }
    password { FFaker::Internet.password }
    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    trait :admin do
      role :admin
    end

    trait :collaborator do
      role :collaborator
    end

    trait :contributor do
      role :collaborator
    end
  end
end
