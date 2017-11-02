class ChangeStatusType < ActiveRecord::Migration[5.1]
  def up
    add_column :mturk_batch_jobs, :convert_status, :integer, :default => 0
    
    # look up the schema's to be able to re-inspect the Project model
    # http://apidock.com/rails/ActiveRecord/Base/reset_column_information/class
    MturkBatchJob.reset_column_information
    
    # loop over the collection
    MturkBatchJob.all.each do |p|
        p.convert_status = 0
        p.save
    end
    
    # remove the older status column
    remove_column :mturk_batch_jobs, :status
    # rename the convert_status to status column
    rename_column :mturk_batch_jobs, :convert_status, :status
  end
  def down
    change_column :mturk_batch_jobs, :status, :string
  end
end
