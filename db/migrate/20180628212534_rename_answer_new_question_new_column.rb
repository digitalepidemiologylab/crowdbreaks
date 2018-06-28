class RenameAnswerNewQuestionNewColumn < ActiveRecord::Migration[5.1]
  def change
    rename_column :answers, :answer_new, :answer
    rename_column :questions, :question_new, :question
  end
end
