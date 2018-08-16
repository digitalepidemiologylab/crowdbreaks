ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation, :role

  index do
    column :username
    column :email
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    column :role
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
      f.input :role
    end
    f.actions
  end

  controller do
    before_create(&:skip_confirmation!)
  end

end
