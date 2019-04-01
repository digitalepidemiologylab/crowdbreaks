class AddOrderColumnToAnswer < ActiveRecord::Migration[5.0]
  def change
    add_column :answers, :order, :integer, :default => 0
  end
end
