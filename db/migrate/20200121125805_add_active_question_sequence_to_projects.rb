class AddActiveQuestionSequenceToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :active_question_sequence_id, :integer, default: 0
  end
end
