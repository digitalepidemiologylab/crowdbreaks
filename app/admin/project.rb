ActiveAdmin.register Project do
  title_translations = []
  desc_translations = []
  Crowdbreaks::Locales.each do |l|
    title_translations.push(('title_'+l).to_sym)
    desc_translations.push(('description_'+l).to_sym)
  end
  permit_params *title_translations, *desc_translations, :es_index_name, :image


  index do
    column "Title" do |p|
      p.title_translations['en']
    end
    column "Description" do |p|
      p.description_translations['en'] if p.description_translations
    end
    column "Elasticsearch index name" do |p|
      p.es_index_name
    end
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs "Project" do
      title_translations.each do |t|
        f.input t
      end
      desc_translations.each do |t|
        f.input t, as: :text
      end
      f.input :image, as: :file, hint: f.object.image.present? ? image_tag(f.object.image.url(:thumb)) : content_tag(:span, "No image yet")
      f.input :es_index_name
    end
    f.actions
  end
end
