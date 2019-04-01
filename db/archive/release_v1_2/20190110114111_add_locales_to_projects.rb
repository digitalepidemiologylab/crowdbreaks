class AddLocalesToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :locales, :string, default: ['en'], array: true
  end
end
