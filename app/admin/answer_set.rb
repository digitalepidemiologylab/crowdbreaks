ActiveAdmin.register AnswerSet do

  permit_params :name, :answer0_id, :answer1_id, :answer2_id, :answer3_id, :answer4_id, :answer5_id, :answer6_id, :answer7_id, :answer8_id, :answer9_id

  form do |f|
    f.inputs "Set name" do
      f.input :name
    end
    f.inputs "Answers" do
      for i in 0..9
        f.input eval(":answer"+i.to_s)
      end
    end
    f.actions
  end


end
