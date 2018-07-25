FactoryGirl.define do
  sequence(:name) { |n| "Batch #{n}" }
  factory :mturk_batch_job do
    association :project
    name
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


def random_id
  ('a'..'z').to_a.shuffle.join
end
