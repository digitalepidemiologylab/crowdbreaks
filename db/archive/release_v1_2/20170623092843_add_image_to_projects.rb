class AddImageToProjects < ActiveRecord::Migration[5.0]
  def up
    add_attachment :projects, :image
  end

  def down
    remove_attachment :projects, :image
  end
end
