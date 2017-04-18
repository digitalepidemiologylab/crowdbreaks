FactoryGirl.define do
  factory :result do
    association :project
    association :answer
    association :question
    association :user
  end
end
