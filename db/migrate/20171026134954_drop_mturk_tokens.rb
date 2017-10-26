class DropMturkTokens < ActiveRecord::Migration[5.1]
  def up
    drop_table :mturk_tokens
  end

  def down
    create_table :mturk_tokens do |t|
      t.string :hit_id
      t.string :token
      t.string :key
      t.boolean :used, default: false, null:false

      t.timestamps
    end
    add_index :mturk_tokens, :token, unique: true
    add_index :mturk_tokens, :key, unique: true
  end
end
