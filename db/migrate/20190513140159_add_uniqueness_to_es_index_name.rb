class AddUniquenessToEsIndexName < ActiveRecord::Migration[5.2]
  def change
    add_index :projects, :es_index_name, :unique => true
  end
end
