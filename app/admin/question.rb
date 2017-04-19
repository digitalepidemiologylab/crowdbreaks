ActiveAdmin.register Question do
  question_translations = []
  Crowdbreaks::Locales.each do |l|
    question_translations.push(('question_'+l).to_sym)
  end
  permit_params *question_translations, :project_id, :answer_set_id

  index do
    column "Question" do |p|
      p.question_translations['en'] if p.question_translations
    end
    column :project
    column :answer_set
    actions
  end

  form do |f|
    f.inputs "Question" do
      question_translations.each do |t|
        f.input t
      end
      f.input :project
      f.input :answer_set
    end
    f.actions
  end
end
