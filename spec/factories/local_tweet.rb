FactoryBot.define do
  factory :local_tweet do
    association :local_batch_job
    tweet_id { '20' }

    trait :invalid_tweet do
      tweet_id { '0' }
    end
  end
end
