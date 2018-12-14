class AddStatusToWorker < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_workers, :status, :integer, default: 0, null: false
  end
end
