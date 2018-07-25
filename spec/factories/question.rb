FactoryGirl.define do
  factory :question do
    association :project
    question FFaker::Lorem.sentence
    instructions FFaker::Lorem.paragraph
  end
end
