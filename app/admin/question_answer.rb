ActiveAdmin.register QuestionAnswer do
  permit_params :answer_id, :question_id, :order

  # Active admin sortable tree setup
  sortable sorting_attribute: :order

  index :as => :sortable do
    label :question do |f|
      'Project: ' + f.question.try(:project).try(:title)[0..20] + ' -- Question: ' + f.question.question[0..20] + ' -- Answer: ' + f.answer.answer[0..20] + ' -- Order: ' + f.order.to_s
    end
    actions
  end

end
