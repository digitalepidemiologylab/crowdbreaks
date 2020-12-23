class CreateMturkWorkerQualificationListMturkWorkerJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :mturk_workers, :mturk_worker_qualification_lists
  end
end
