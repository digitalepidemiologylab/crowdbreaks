class AddAnnotationModeColumnToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :annotation_mode, :integer, default: 0, null: false
  end
end
