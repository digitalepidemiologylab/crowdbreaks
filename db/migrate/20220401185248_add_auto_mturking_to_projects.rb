class AddAutoMturkingToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :auto_mturking, :boolean, default: false, null: false
  end
end
