class AddFieldsToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :keywords, :string, array: true
    add_column :projects, :public, :boolean, default: false, null: false
    add_column :projects, :active_stream, :boolean, default: true, null: false
  end
end
