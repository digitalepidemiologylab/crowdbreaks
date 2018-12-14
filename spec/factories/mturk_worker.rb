FactoryBot.define do
  sequence(:worker_id) { |n| n }
  factory :mturk_worker do
    worker_id
    trait :blacklisted do
      status { 1 }
    end
  end
end
