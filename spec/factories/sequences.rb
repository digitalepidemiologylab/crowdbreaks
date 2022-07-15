FactoryBot.define do
  sequence(:local_batch_name) { |n| "batch_#{n}" }
  sequence(:mturk_batch_name) { |n| "batch_#{n}" }
end
