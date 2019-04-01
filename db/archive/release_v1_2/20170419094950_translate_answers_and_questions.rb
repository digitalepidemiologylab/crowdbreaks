class TranslateAnswersAndQuestions < ActiveRecord::Migration[5.0]
  def up
    remove_column :answers, :answer
    add_column :answers, :answer_translations, 'jsonb'

    remove_column :questions, :question
    add_column :questions, :question_translations, 'jsonb'
  end

  def down
    add_column :answers, :answer, :string
    remove_column :answers, :answer_translations

    add_column :questions, :question, :string
    remove_column :questions, :question_translations
  end
end
