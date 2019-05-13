class CloneEsIndexNameColumnToNameColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :name, :string, default: '', null: false

    reversible do |dir|
      dir.up { 
        Project.find_each do |project|
          if project.es_index_name.present?
            project.update_attribute(:name, project.es_index_name)
          end
        end
      }
    end
  end
end
