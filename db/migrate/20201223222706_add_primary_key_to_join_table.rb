class AddPrimaryKeyToJoinTable < ActiveRecord::Migration[5.2]
  def change
    add_column :qualified_workers, :id, :primary_key
  end
end
