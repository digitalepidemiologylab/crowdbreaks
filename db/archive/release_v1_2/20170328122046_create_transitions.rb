class CreateTransitions < ActiveRecord::Migration[5.0]
  def change
    create_table :transitions do |t|
      t.references :from_question, references: :questions
      t.references :answer, references: :answers
      t.references :to_question, references: :questions
      t.references :project, references: :projects
      t.float :transition_probability

      t.timestamps
    end
  end
end
