class RemoveAdminColumnFromUsers < ActiveRecord::Migration[5.1]
  def up
    User.where(admin: true).update_all(role: 3)
    remove_column :users, :admin
  end

  def down
    add_column :users, :admin, :boolean, null: false, default: false
    User.where(role: 2).update_all(admin: true)
  end
end
