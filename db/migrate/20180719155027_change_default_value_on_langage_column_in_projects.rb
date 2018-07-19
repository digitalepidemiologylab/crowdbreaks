class ChangeDefaultValueOnLangageColumnInProjects < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:projects, :lang, from: ["en"], to: [])
  end
end
