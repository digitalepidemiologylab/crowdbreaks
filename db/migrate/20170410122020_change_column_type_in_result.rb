class ChangeColumnTypeInResult < ActiveRecord::Migration[5.0]
  def change
    change_column :results, :tweet_id, :bigint
  end
end
