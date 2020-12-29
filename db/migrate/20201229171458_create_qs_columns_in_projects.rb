class CreateQsColumnsInProjects < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :primary, :boolean, default: true, null: false
    add_column :projects, :question_sequence_name, :string

    Project.all.each_with_index do |p, i|
      unless p.es_index_name.present?
        p.primary = false
        p.question_sequence_name = "qs-#{i}"
        p.save(touch: false)
      end
    end
  end

  def down
    remove_column :projects, :primary, :boolean
    remove_column :projects, :question_sequence_name
  end
end
