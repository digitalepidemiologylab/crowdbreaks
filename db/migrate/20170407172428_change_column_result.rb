class ChangeColumnResult < ActiveRecord::Migration[5.0]
  def change
    change_column :results, :tweet_id, :integer
  end
end
