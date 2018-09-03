class AddStorageModeToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :storage_mode, :integer, default: 0
  end
end
