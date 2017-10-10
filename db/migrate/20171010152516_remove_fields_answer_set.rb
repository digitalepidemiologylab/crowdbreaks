class RemoveFieldsAnswerSet < ActiveRecord::Migration[5.1]
  def change
    remove_reference :answer_sets, :answer0, index: true
    remove_reference :answer_sets, :answer1, index: true
    remove_reference :answer_sets, :answer2, index: true
    remove_reference :answer_sets, :answer3, index: true
    remove_reference :answer_sets, :answer4, index: true
    remove_reference :answer_sets, :answer5, index: true
    remove_reference :answer_sets, :answer6, index: true
    remove_reference :answer_sets, :answer7, index: true
    remove_reference :answer_sets, :answer8, index: true
    remove_reference :answer_sets, :answer9, index: true
    remove_column :answer_sets, :name, :string
  end
end
