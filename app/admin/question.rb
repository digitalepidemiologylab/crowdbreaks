ActiveAdmin.register Question do
  question_translations = []
  Crowdbreaks::Locales.each do |l|
    question_translations.push(('question_'+l).to_sym)
  end
  permit_params *question_translations, :question_new, :project_id, :meta_field, :use_for_relevance_score, :answer_ids => []

  index do
    column "Question" do |p|
      p.question_translations['en'] if p.question_translations
    end
    column :project
    column :meta_field
    column :use_for_relevance_score
    actions
  end

  form do |f|
    f.inputs "Question" do
      question_translations.each do |t|
        f.input t
      end
      f.input :question_new
      f.input :project
      f.input :meta_field, label: 'Meta field name in ES (optional)'
      f.input :answers, as: :check_boxes, :collection => Answer.all.map{ |a|  
        answer_text = a.answer
        answer_text += "      (label: #{a.label})" if not a.label.nil?
        [answer_text, a.id]  
      }
      f.input :use_for_relevance_score
    end
    f.actions
  end
end
