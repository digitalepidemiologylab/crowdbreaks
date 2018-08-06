FactoryBot.define do
  sequence(:worker_id) { |n| n }
  factory :mturk_worker do
    worker_id
  end
end
