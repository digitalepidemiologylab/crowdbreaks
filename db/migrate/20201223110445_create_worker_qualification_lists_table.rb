class CreateWorkerQualificationListsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :mturk_worker_qualification_lists do |t|
      t.string "name"
      t.string "qualification_type_id"
      t.timestamps
    end
  end
end
