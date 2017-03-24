ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation, :admin

  index do
    column :username
    column :email
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    column :admin
    column :updated_at
    column :created_at
    actions
  end

  form do |f|
    f.inputs "User Details" do
      f.input :username
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :admin, :label => "Admin status"
    end
    f.actions
  end

  controller do
    before_create do |user|
      user.skip_confirmation!
    end
  end

end
