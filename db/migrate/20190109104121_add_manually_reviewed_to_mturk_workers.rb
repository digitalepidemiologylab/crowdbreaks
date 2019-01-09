class AddManuallyReviewedToMturkWorkers < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_workers, :manually_reviewed, :boolean, default: false, null: false
  end
end
