ActiveAdmin.register Answer do
  permit_params :answer, :order
  config.sort_order = 'order_asc'

  index do
    column :answer
    column "Key (automatically generated)", :key
    column :order
    actions
  end

  form do |f|
    f.inputs "Answer" do
      f.input :answer
      f.input :order
    end
    f.actions
  end
end
