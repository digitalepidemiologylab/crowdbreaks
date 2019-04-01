class RenameTableAnswerSetToQuestionAnswer < ActiveRecord::Migration[5.1]
  def change
    rename_table :answer_sets, :question_answers
  end
end
