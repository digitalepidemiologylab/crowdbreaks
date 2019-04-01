class AddColorToAnswer < ActiveRecord::Migration[5.0]
  def change
    add_column :answers, :color, :string
  end
end
