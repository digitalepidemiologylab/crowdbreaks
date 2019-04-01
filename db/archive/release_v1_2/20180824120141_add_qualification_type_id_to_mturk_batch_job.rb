class AddQualificationTypeIdToMturkBatchJob < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :qualification_type_id, :string
  end
end
