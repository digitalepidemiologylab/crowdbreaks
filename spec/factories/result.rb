FactoryBot.define do
  factory :result do
    association :project
    association :answer
    association :question
    association :user

    trait :through_mturk do
      association :task
    end
  end
end
