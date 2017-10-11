class AddOrderColumnToQuestionAnswers < ActiveRecord::Migration[5.1]
  def change
    add_column :question_answers, :order, :integer, :default => 0, :null => false
  end
end
