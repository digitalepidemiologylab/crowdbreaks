FactoryGirl.define do
  factory :answer do
    sequence(:answer) { |n| "AAnswer #{n}" }
  end
end
