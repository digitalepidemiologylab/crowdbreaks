FactoryBot.define do
  factory :mturk_batch_job do
    association :project
    name {generate(:mturk_batch_name)}
    title FFaker::Lorem.word
    description FFaker::Lorem.paragraph
    sandbox true
    reward 0.2
    keywords FFaker::Lorem.words.join(' ')
    lifetime_in_seconds 3*24*3600
    auto_approval_delay_in_seconds 3*24*3600
    assignment_duration_in_seconds 20*60
    instructions FFaker::Lorem.paragraph
  end
end
