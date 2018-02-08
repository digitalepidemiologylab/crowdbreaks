class AddFieldToResults < ActiveRecord::Migration[5.1]
  def change
    add_column :results, :mturk_result, :boolean, default: false, null: false
  end
end
