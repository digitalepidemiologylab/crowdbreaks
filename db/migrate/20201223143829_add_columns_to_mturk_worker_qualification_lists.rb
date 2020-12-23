class AddColumnsToMturkWorkerQualificationLists < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_worker_qualification_lists, :description, :text, default: ''
    add_column :mturk_worker_qualification_lists, :status, :integer, default: 0, null: false
  end
end
