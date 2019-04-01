class AddMetaFieldToQuestion < ActiveRecord::Migration[5.0]
  def up
    add_column :questions, :meta_field, 'string'
  end
  def down
    remove_column :questions, :meta_field
  end
end
