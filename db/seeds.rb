# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#

if Project.all.size == 0
  project = Project.create(title_translations: {"de"=>"Messung des Impfbefindens", "en"=>"Vaccine sentiment tracking"},
    description_translations: {"de"=>"Bei diesem Projekt geht es darum herauszufinden, was Personen von Impfungen halten. Das Befinden über Impfungen ist ein guter Indikator für die Impfquote, welche wiederum sehr wichtig ist bei der Vorhersage über die Ausbreitung einer Krankheit. Zusätzlich kann das Ermitteln dieser \"Impfstimmung\" (vaccine sentiment auf Englisch) in mathematische Modelle einfliessen und somit diese verbessern. Ziel dieses Projekts ist auch die Erhebung der geographischen Abhängigkeit der Impfstimmung.", "en"=>"This project revolves around the question on how people feel about the topic of vaccination. Vaccine sentiment is strongly tied to vaccination coverage which in turn is an important factor in disease prevention. Tracking vaccine sentiment can improve models on how we predict and what decisions we take in order to fight diseases. Additionally, our aim is to properly determine the vaccine sentiments based on geographical location."},
    es_index_name: "project_vaccine_sentiment")
  
  # create example question sequence
  a1 = Answer.create(order: 0, answer_translations: {"de"=>"Ja", "en"=>"Yes"})
  a2 = Answer.create(order: 1, answer_translations: {"de"=>"Vielleicht", "en"=>"Maybe"})
  a3 = Answer.create(order: 2, answer_translations: {"de"=>"Nein", "en"=>"No"})
  a4 = Answer.create(order: 0, answer_translations: {"de"=>"Positiv", "en"=>"Negativ"})
  a5 = Answer.create(order: 1, answer_translations: {"de"=>"Neutral", "en"=>"Neutral"})
  a6 = Answer.create(order: 2, answer_translations: {"de"=>"Negativ", "en"=>"Negative"})
  as1 = AnswerSet.create(name: 'Default', answer0_id: a1.id, answer1_id: a2.id, answer2_id: a3.id)
  as2 = AnswerSet.create(name: 'positive_negative', answer0_id: a4.id, answer1_id: a5.id, answer2_id: a6.id)
  q1 = Question.create(project_id: project.id, answer_set_id: as1.id, 
                       question_translations: {"de"=>"Geht es bei diesem Tweet um Impfungen?", "en"=>"Is this tweet related to vaccines?"},
                       meta_field: "relevant_to_vaccines")
  q2 = Question.create(project_id: project.id, answer_set_id: as2.id, 
                       question_translations: {"de"=>"Äussert sich dieser Tweet positiv oder negativ über Impfungen?", "en"=>"Is this tweet positive or negative about the idea of vaccinations?"},
                       meta_field: "sentiment")
  t1 = Transition.create(from_question_id: nil, to_question_id: q1.id, project_id: project.id)
  t2 = Transition.create(from_question_id: q1.id, to_question_id: q2.id, project_id: project.id, answer_id: a1.id)
end

if User.all.size == 0
  User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password', admin: true, confirmed_at: Time.now) 
end



