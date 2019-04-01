class AddElasticsearchIndexNameToProjects < ActiveRecord::Migration[5.0]
  def up
    add_column :projects, :es_index_name, 'string'
  end
  def down
    remove_column :projects, :es_index_name
  end
end
