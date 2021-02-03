class AddLastUpdatedQuestionSequenceDateToProjects < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :last_question_sequence_created_at, :timestamp
    Project.primary.each do |project|
      project.update_attribute(:last_question_sequence_created_at, project.question_sequences.pluck(:created_at).max)
    end
  end

  def down
    remove_column :projects, :last_question_sequence_updated_at, :timestamp
  end
end
