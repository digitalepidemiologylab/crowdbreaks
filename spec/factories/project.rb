FactoryGirl.define do
  sequence(:title) { |n| "Title #{n}" }
  factory :project do
    title 
    description "Description"
  end
end
