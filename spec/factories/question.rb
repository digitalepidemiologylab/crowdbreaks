FactoryBot.define do
  factory :question do
    association :project
    add_attribute(:question) { FFaker::Lorem.sentence }
    instructions { FFaker::Lorem.paragraph }
  end
end
