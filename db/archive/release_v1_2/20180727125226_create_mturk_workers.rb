class CreateMturkWorkers < ActiveRecord::Migration[5.1]
  def change
    create_table :mturk_workers do |t|
      t.string :worker_id
    end
  end
end
