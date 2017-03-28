ActiveAdmin.register Transition do
  permit_params :from_question_id, :answer_id, :to_question_id, :project_id, :transition_probability

  index do 
    column 'From Question' do |f|
      f.from_question.question.slice(0, 30) unless f.from_question.nil?
    end
    column :answer
    column 'To Question' do |f|
      f.to_question.question.slice(0, 30) unless f.to_question.nil?
    end
    column :project
    column :transition_probability
    actions
  end


  form do |f| 
    f.inputs "Transition" do
      f.input :from_question
      f.input :answer
      f.input :to_question
      f.input :project
    end
    f.actions
  end


end
