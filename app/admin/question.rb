ActiveAdmin.register Question do
  permit_params :question, :project_id, :answer_set_id

  index do
    column :question
    column :project
    column :answer_set
    actions
  end


  form do |f| 
    f.inputs "Question" do
      f.input :question
      f.input :project
      f.input :answer_set
    end
  end

end
