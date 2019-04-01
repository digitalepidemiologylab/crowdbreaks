class CreateResults < ActiveRecord::Migration[5.0]
  def change
    create_table :results do |t|
      t.references :question, references: :questions
      t.references :answer, references: :answers
      t.references :user, references: :users
      t.references :project, references: :projects

      t.timestamps
    end
  end
end
