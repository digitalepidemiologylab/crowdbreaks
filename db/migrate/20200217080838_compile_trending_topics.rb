class CompileTrendingTopics < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :compile_trending_topics, :boolean, default: false, null: false
  end
end
