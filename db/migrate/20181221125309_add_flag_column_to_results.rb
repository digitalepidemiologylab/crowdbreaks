class AddFlagColumnToResults < ActiveRecord::Migration[5.2]
  def change
    add_column :results, :flag, :integer, default: 0, null: false
  end
end
