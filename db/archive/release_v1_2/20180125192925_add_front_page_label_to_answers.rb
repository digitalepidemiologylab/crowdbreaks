class AddFrontPageLabelToAnswers < ActiveRecord::Migration[5.1]
  def change
    add_column :answers, :label, :string, default: nil
  end
end
