class AddAccessibleByColumnToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :accessible_by_email_pattern, :string, array: true, default: []
  end
end
