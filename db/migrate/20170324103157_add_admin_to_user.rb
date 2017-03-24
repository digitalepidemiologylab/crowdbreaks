class AddAdminToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :admin, :boolean, :null => false, :default => false

    User.create! do |r|
      r.email      = 'default@example.com'
      r.password   = 'password'
      r.admin = true
    end
  end
end
