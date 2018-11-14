FactoryBot.define do
  factory :mturk_tweet do
    association :mturk_batch_job
    # Tweet ID of 20 is returned as valid by stubbed API, 0 invalid.
    tweet_id { '20' }

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
