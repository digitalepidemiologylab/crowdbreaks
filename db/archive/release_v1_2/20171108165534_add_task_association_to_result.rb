class AddTaskAssociationToResult < ActiveRecord::Migration[5.1]
  def change
    remove_reference :results, :mturk_token, index: true
    add_reference :results, :task, foreign_key: true
  end
end
