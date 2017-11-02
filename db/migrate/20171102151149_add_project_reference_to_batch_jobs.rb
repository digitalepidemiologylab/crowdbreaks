class AddProjectReferenceToBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_reference :mturk_batch_jobs, :project, foreign_key: true
  end
end
