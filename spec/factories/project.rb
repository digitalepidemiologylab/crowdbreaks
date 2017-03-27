FactoryGirl.define do
  factory :project do
    title { FFaker::Name.name  }
    description { FFaker::Lorem.paragraphs(paragraph_count = 3) }
  end
end
