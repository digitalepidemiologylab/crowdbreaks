FactoryBot.define do
  factory :transition do
    association :to_question, factory: :question
    association :from_question, factory: :question
    association :project

    trait :starting_question do
      from_question { nil }
    end

  end
end
