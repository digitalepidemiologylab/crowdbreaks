FactoryBot.define do
  sequence(:tweet_id) { |n| n }
  factory :mturk_tweet do
    association :mturk_batch_job
    tweet_id
  end
end
