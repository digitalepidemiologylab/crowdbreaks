FactoryBot.define do
  factory :answer do
    add_attribute(:answer) { FFaker::Lorem.word }
    label FFaker::Lorem.word
    color 'btn-primary'
  end
end
