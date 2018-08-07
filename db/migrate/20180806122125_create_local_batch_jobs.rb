class CreateLocalBatchJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :local_batch_jobs do |t|
      t.string :name
      t.references :project
      t.text "instructions", default: ""

      t.timestamps
    end
  end
end
