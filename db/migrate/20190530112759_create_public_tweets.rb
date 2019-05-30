class CreatePublicTweets < ActiveRecord::Migration[5.2]
  def change
    create_table :public_tweets do |t|
      t.bigint :tweet_id
      t.text :tweet_text
      t.references :project, foreign_key: true
      t.integer :availability, default: 0
      t.timestamps
    end
    add_index :public_tweets, :tweet_id
    add_index :public_tweets, :availability
  end
end
