FactoryBot.define do
  factory :mturk_tweet do
    association :mturk_batch_job
    tweet_id '20'

    trait :invalid_tweet do
      tweet_id '0'
    end
  end
end
