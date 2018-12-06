class AddTimestampsToMturkWorkers < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :mturk_workers, default: DateTime.now
    change_column_default :mturk_workers, :created_at, nil
    change_column_default :mturk_workers, :updated_at, nil
  end
end
