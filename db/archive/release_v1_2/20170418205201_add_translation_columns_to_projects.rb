class AddTranslationColumnsToProjects < ActiveRecord::Migration[5.0]
  def up
    add_column :projects, :title_translations, 'jsonb'
    add_column :projects, :description_translations,  'jsonb'
  end
  def down
    remove_column :projects, :title_translations
    remove_column :projects, :description_translations
  end
end
