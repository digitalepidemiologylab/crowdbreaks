class AddRelevanceColumnToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :questions, :use_for_relevance_score, :boolean, null: false, default: false
  end
end
