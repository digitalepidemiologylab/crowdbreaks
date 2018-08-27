class RemoveMturkResultFromResults < ActiveRecord::Migration[5.1]
  def up
    Result.where(mturk_result: true).update_all(res_type: 2)
    Result.where.not(local_batch_job_id: nil).update_all(res_type: 1)
    remove_column :results, :mturk_result
  end

  def down
    add_column :results, :mturk_result, :boolean, null: false, default: false
    Result.where(res_type: 2).update_all(mturk_result: true)
  end
end
