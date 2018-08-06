class ReplaceAssignmentIdByTimeOfAssignmentOnTasks < ActiveRecord::Migration[5.1]
  def change
    remove_column :tasks, :assignment_id, :string
    add_column :tasks, :time_assigned, :datetime
  end
end
