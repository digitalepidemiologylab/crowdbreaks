FactoryBot.define do
  factory :mturk_tweet do
    association :mturk_batch_job
    # All Tweet IDs are returned as valid by stubbed API, except for 0
    tweet_id { '1012627301358620672' }

    trait :available do
      availability { :available }
    end

    trait :unavailable do
      availability { :unavailable }
    end

    trait :unknown_invalid do
      tweet_id { '0' } 
    end

    trait :wrongly_set_to_available do
      availability { :available }
      tweet_id { '0' } 
    end
  end
end
