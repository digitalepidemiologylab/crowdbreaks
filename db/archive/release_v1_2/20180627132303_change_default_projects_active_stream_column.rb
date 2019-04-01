class ChangeDefaultProjectsActiveStreamColumn < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:projects, :active_stream, from: true, to: false)
  end
end
