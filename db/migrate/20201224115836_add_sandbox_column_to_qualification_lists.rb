class AddSandboxColumnToQualificationLists < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_worker_qualification_lists, :sandbox, :boolean, default: true
  end
end
