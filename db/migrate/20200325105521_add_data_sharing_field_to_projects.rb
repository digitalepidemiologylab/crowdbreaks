class AddDataSharingFieldToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :compile_data_dump_ids, :boolean, default: false, null: false
  end
end
