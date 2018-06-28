ActiveAdmin.register Answer do
  permit_params :color, :label, :answer
  config.sort_order = :created_at_asc

  index do
    column :answer
    column "Key (automatically generated)", :key
    column :color
    column "Label (hidden)", :label
    actions
  end

  form do |f|
    f.inputs "Answer" do
      f.input :answer
      f.input :color, as: 'select', collection: Answer::COLORS
      f.input :label, label: 'label (hidden), optional', as: 'select', collection: Answer::LABELS
    end
    f.actions
  end
end
