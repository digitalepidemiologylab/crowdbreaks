class AddAnswerTypeToAnswers < ActiveRecord::Migration[5.2]
  def change
    add_column :answers, :answer_type, :integer, default: 0, null: false
  end
end
