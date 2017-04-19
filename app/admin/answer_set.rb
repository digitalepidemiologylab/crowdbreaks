ActiveAdmin.register AnswerSet do

  permit_params :name, :answer0_id, :answer1_id, :answer2_id, :answer3_id, :answer4_id, :answer5_id, :answer6_id, :answer7_id, :answer8_id, :answer9_id

  form do |f|
    f.inputs "Set name" do
      f.input :name
    end
    f.inputs "Answers" do
      (0..9).each do |i|
        f.input ('answer' + i.to_s).to_sym
      end
    end
    f.actions
  end
end
