FactoryBot.define do
  factory :answer do
    association :questions
    answer FFaker::Lorem.word
    label FFaker::Lorem.word
    color 'btn-primary'
  end
end
