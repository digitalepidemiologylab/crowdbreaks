FactoryBot.define do
  sequence(:hit_id) { |n| "hit_#{n}" }

  factory :task do
    association :mturk_batch_job

    trait :unsubmitted do
      lifecycle_status 0
    end

    trait :submitted do
      lifecycle_status 1
      hit_id
      time_submitted Time.zone.now
    end

    trait :reviewable do
      lifecycle_status 2
      hit_id
      association :mturk_worker
      association :mturk_tweet
      time_submitted 10.days.ago
      time_assigned 30.minutes.ago
      time_completed 25.minutes.ago
    end

    trait :disposed do
      lifecycle_status 3
      hit_id
      association :mturk_worker
      association :mturk_tweet
      time_submitted 10.days.ago
      time_assigned 4.days.ago
      time_completed 3.days.ago
    end

    trait :accepted do
      lifecycle_status 4
      hit_id
      association :mturk_worker
      association :mturk_tweet
      time_submitted 10.days.ago
      time_assigned 4.days.ago
      time_completed 3.days.ago
    end
  end
end
