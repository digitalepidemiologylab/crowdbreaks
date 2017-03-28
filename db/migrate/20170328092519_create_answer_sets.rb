class CreateAnswerSets < ActiveRecord::Migration[5.0]
  def change
    create_table :answer_sets do |t|
      t.string :name
      t.references :answer0, references: :answers
      t.references :answer1, references: :answers
      t.references :answer2, references: :answers
      t.references :answer3, references: :answers
      t.references :answer4, references: :answers
      t.references :answer5, references: :answers
      t.references :answer6, references: :answers
      t.references :answer7, references: :answers
      t.references :answer8, references: :answers
      t.references :answer9, references: :answers

      t.timestamps
    end
  end
end
