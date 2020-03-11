class AddModelEndpointsJsonbColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :model_endpoints, :jsonb, default: {}, null: false
  end
end
