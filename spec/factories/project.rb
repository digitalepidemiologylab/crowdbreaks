FactoryGirl.define do
  sequence(:title) { |n| "Title #{n}" }
  factory :project do
    title 
    description "Description"
    public false
    trait :public do
      public true
    end
  end
end
