class AddColumnAnswerSetToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_reference :questions, :answer_set, index: true
  end
end
