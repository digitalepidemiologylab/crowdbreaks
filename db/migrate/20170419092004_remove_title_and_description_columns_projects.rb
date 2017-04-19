class RemoveTitleAndDescriptionColumnsProjects < ActiveRecord::Migration[5.0]
  def up
    remove_column :projects, :title
    remove_column :projects, :description
  end

  def down
    add_column :projects, :title, :string
    add_column :projects, :description, :text
  end
end
