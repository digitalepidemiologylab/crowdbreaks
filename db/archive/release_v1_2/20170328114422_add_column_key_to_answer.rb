class AddColumnKeyToAnswer < ActiveRecord::Migration[5.0]
  def change
    add_column :answers, :key, :string
  end
end
