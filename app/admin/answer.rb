ActiveAdmin.register Answer do
  permit_params :answer

  index do
    column :answer
    column "Key (automatically generated)", :key 
    actions
  end


  form do |f|
    f.inputs "Answer" do
      f.input :answer
    end
    f.actions
  end
end
