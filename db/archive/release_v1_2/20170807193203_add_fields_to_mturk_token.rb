class AddFieldsToMturkToken < ActiveRecord::Migration[5.0]
  def change
    add_column :mturk_tokens, :assignment_id, :string
    add_column :mturk_tokens, :worker_id, :string
    add_column :mturk_tokens, :questions_answered, :integer
    add_column :mturk_tokens, :bonus_sent, :boolean, default: false, null: false
  end
end
