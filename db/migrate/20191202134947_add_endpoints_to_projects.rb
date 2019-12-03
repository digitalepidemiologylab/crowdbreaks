class AddEndpointsToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :model_endpoints, :string, array: true, default: []
  end
end
