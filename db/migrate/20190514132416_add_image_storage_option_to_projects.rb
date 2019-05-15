class AddImageStorageOptionToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :image_storage_mode, :integer, default: 0, null: false
  end
end
