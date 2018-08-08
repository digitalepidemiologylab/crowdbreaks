FactoryBot.define do
  factory :mturk_tweet do
    association :mturk_batch_job
    tweet_id
  end
end
