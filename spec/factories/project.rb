FactoryGirl.define do
  factory :project do
    title { FFaker::Name.name }
    description { FFaker::Lorem.paragraphs(3) }
  end
end
