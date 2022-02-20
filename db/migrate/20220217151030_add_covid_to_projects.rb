class AddCovidToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :covid, :boolean, default: false, null: false
  end
end
