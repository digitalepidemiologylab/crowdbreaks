FactoryBot.define do
  sequence(:local_batch_name) { |n| "Batch #{n}" }
  sequence(:mturk_batch_name) { |n| "Batch #{n}" }
  sequence(:tweet_id) { |n| n }
end
