class AddInstructionToQuestion < ActiveRecord::Migration[5.1]
  def change
    add_column :questions, :instructions, :text, default: ""
  end
end
