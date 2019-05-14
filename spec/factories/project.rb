FactoryBot.define do
  sequence(:title) { |n| "Title #{n}" }
  sequence(:name) { |n| "project_#{n}" }
  factory :project do
    title 
    name
    description { "Description" }
    public { false }
    trait :public do
      public { true }
    end
  end
end
