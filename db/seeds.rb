# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
Project.destroy_all
Project.create!(title: "Project 1", description: Faker::Lorem.paragraph(paragraph_count=8))
Project.create!(title: "Project 2", description: Faker::Lorem.paragraph(paragraph_count=8))
Project.create!(title: "Project 3", description: Faker::Lorem.paragraph(paragraph_count=8))
