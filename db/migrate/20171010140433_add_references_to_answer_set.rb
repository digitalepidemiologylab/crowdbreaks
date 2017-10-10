class AddReferencesToAnswerSet < ActiveRecord::Migration[5.1]
  def change
    add_reference :answer_sets, :question, foreign_key: true
    add_reference :answer_sets, :answer, foreign_key: true
  end
end
