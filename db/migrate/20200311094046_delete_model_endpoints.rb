class DeleteModelEndpoints < ActiveRecord::Migration[5.2]
  def change
    remove_column :projects, :model_endpoints
  end
end
