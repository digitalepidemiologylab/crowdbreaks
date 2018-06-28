class RemoveQuestionAnswerTranslationsFields < ActiveRecord::Migration[5.1]
  def up
    remove_column :answers, :answer_translations
    remove_column :questions, :question_translations
  end

  def down
    add_column :answers, :answer_translations, :jsonb
    add_column :questions, :question_translations, :jsonb
  end
end
