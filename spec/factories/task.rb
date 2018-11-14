FactoryBot.define do
  sequence(:hit_id) { |n| "hit_#{n}" }

  factory :task do
    association :mturk_batch_job

    trait :unsubmitted do
      lifecycle_status { 0 }
    end

    trait :submitted do
      lifecycle_status { 1 }
      hit_id
      time_submitted { Time.current }
    end

    trait :assigned do
      lifecycle_status { 2 }
      hit_id
      association :mturk_worker
      association :mturk_tweet
      time_submitted { 10.days.ago }
      # time_assigned 5.minutes.ago
    end

    trait :completed do
      lifecycle_status { 3 }
      hit_id
      association :mturk_worker
      association :mturk_tweet
      time_submitted { 10.days.ago }
      # time_assigned 5.days.ago
      time_completed { 1.minutes.ago }
    end
  end
end
