class AddAnnotationDisplayModeToLocalBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :local_batch_jobs, :annotation_display_mode, :integer, default: 0, null: false
  end
end
