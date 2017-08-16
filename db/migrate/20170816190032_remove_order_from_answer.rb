class RemoveOrderFromAnswer < ActiveRecord::Migration[5.0]
  def change
    remove_column :answers, :order
  end
end
