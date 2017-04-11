# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
if Project.all.size == 0
  Project.create!(title: "Vaccine sentiment tracking", description: "This project revolves around the question on how people feel about the topic of vaccination. Vaccine sentiment is strongly tied to vaccination coverage which in turn is an important factor in disease prevention. Tracking vaccine sentiment can improve models on how we predict and what decisions we take in order to fight diseases. Additionally, our aim is to properly determine the vaccine sentiments based on geographical location.")
  Project.create!(title: "Project 2", description: Faker::Lorem.paragraph(8))
  Project.create!(title: "Project 3", description: Faker::Lorem.paragraph(8))
end

if User.all.size == 0
  User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password', admin: true) 
end


if ActiveTweet.all.size == 0
  ActiveTweet.create!(tweet_id: 847878099614171136, project_id: 1)
end




