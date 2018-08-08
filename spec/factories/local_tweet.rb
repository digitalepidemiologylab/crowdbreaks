FactoryBot.define do
  factory :local_tweet do
    association :local_batch_job
    tweet_id {generate(:tweet_id)}
  end
end
