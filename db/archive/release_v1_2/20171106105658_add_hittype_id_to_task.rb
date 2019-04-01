class AddHittypeIdToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :hittype_id, :string
  end
end
