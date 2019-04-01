class AddQuestionAndAnswerTags < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :tag, :string, default: ''
    add_column :answers, :tag, :string, default: ''
  end
end
