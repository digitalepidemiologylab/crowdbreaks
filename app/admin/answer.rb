ActiveAdmin.register Answer do
  answer_translations = []
  Crowdbreaks::Locales.each do |l|
    answer_translations.push(('answer_'+l).to_sym)
  end
  permit_params *answer_translations, :color, :label
  config.sort_order = :created_at_asc

  index do
    column "Answer" do |p|
      p.answer_translations['en'] if p.answer_translations
    end
    column "Key (automatically generated)", :key
    column :color
    column "Label (hidden)", :label
    actions
  end

  form do |f|
    f.inputs "Answer" do
      answer_translations.each do |t|
        f.input t
      end
      f.input :color, as: 'select', collection: Answer::COLORS
      f.input :label, label: 'label (hidden), optional', as: 'select', collection: Answer::LABELS
    end
    f.actions
  end
end
