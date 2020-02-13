class AddCollectPopularContentColumnToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :compile_trending_tweets, :boolean, default: false
  end
end
