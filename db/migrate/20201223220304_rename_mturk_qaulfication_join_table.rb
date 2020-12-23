class RenameMturkQaulficationJoinTable < ActiveRecord::Migration[5.2]
  def change
    rename_table :mturk_worker_qualification_lists_workers, :qualified_workers
  end
end
