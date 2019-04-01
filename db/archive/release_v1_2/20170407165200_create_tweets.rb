class CreateTweets < ActiveRecord::Migration[5.0]
  def change
    create_table :tweets do |t|
      t.integer :tweet_id
      t.references :project, references: :projects
      t.integer :num_answers
      t.float :uncertainty

      t.timestamps
    end
  end
end
