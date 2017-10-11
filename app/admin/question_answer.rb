ActiveAdmin.register QuestionAnswer do
  permit_params :answer_id, :question_id, :order

  # Active admin sortable tree setup
  sortable sorting_attribute: :order

  index :as => :sortable do
    label :question do |f|
      'Project: ' + f.question.project.title[0..20] + ' -- Question: ' + f.question.question_translations['en'][0..20] + ' -- Answer: ' + f.answer.answer_translations['en'][0..20] + ' -- Order: ' + f.order.to_s
    end
    actions
  end

end
