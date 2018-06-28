ActiveAdmin.register Question do
  permit_params :question, :project_id, :meta_field, :use_for_relevance_score, :answer_ids => []

  index do
    column :question
    column :project
    column :meta_field
    column :use_for_relevance_score
    actions
  end

  form do |f|
    f.inputs "Question" do
      f.input :question
      f.input :project
      f.input :meta_field, label: 'Meta field name in ES (optional)'
      f.input :answers, as: :check_boxes, :collection => Answer.all.map{ |a|  
        answer_text = a.answer
        answer_text += "      (label: #{a.label})" if not a.label.nil?
        [answer_text, a.id]  
      }
      f.input :use_for_relevance_score
    end
    f.actions
  end
end
