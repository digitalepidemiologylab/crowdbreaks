class AddPlainAnswerAndQuestionField < ActiveRecord::Migration[5.1]
  def up
    add_column :questions, :question_new, :text
    add_column :answers, :answer_new, :string
  end

  def down
    remove_column :questions, :question_new
    remove_column :answers, :answer_new
  end
end
