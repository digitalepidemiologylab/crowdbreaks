FactoryBot.define do
  factory :local_batch_job do
    association :project
    name { generate(:local_batch_name) }
    instructions { FFaker::Lorem.paragraph }
  end
end
