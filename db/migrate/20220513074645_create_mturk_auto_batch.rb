class CreateMturkAutoBatch < ActiveRecord::Migration[5.2]
  def change
    create_table :mturk_auto_batches do |t|
      t.boolean :evaluated, null: false, default: false

      t.timestamps
    end
  end
end
