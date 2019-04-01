class RemoveAnswerSetReferenceFromQuestions < ActiveRecord::Migration[5.1]
  def change
    remove_reference :questions, :answer_set, index: true
  end
end
