FactoryBot.define do
  factory :result do
    association :project
    association :answer
    association :question
    association :user

    trait :through_mturk do
      association :task
    end

    trait :through_local_batch do
      association :local_batch_job
    end
  end
end
