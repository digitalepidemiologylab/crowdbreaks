class AddTypeToResults < ActiveRecord::Migration[5.1]
  def change
    add_column :results, :res_type, :integer, null: false, default: 0
  end
end
