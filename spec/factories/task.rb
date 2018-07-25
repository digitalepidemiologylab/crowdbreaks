FactoryGirl.define do
  factory :task do
    association :mturk_batch_job
    tweet_id random_id
    assignment_id nil
    time_submitted nil
    time_completed nil
    worker_id nil
    hittype_id nil

    trait :unsubmitted do
      lifecycle_status 0
    end

    trait :submitted do
      lifecycle_status 1
      hit_id random_id
      time_submitted Time.zone.now
      hittype_id random_id
    end

    trait :reviewable do
      lifecycle_status 2
      hit_id random_id
      time_submitted 10.days.ago
      time_completed Time.zone.now
      worker_id random_id
      assignment_id random_id
      hittype_id random_id
    end

    trait :reviewable do
      lifecycle_status 3
      hit_id random_id
      time_submitted 10.days.ago
      time_completed Time.zone.now
      worker_id random_id
      assignment_id random_id
      hittype_id random_id
    end

    trait :disposed do
      lifecycle_status 4
      hit_id random_id
      time_submitted 10.days.ago
      time_completed Time.zone.now
      worker_id random_id
      assignment_id random_id
      hittype_id random_id
    end

    trait :accepted do
      lifecycle_status 5
      hit_id random_id
      time_submitted 10.days.ago
      time_completed Time.zone.now
      worker_id random_id
      assignment_id random_id
      hittype_id random_id
    end
  end
end


def random_id
  ('a'..'z').to_a.shuffle.join
end
