class CreatePublicTweetsJob < ApplicationJob
  queue_as :default

  def perform(project_id, user_id, tweet_rows, destroy_first: false)
    project = Project.find_by(id: project_id)
    return unless project.present?

    if destroy_first
      project.public_tweets.find_each do |public_tweet|
        if not Result.exists?(tweet_id: public_tweet.tweet_id)
          public_tweet.destroy!
        end
      end
    end

    total_count = tweet_rows.count
    prev_percentage = 0
    if total_count > 0
      tv = TweetValidation.new
      tweet_rows.each_with_index do |row, i|
        pt = PublicTweet.where(tweet_id: row[0], tweet_text: row.length == 1 ? "" : row[1], project: project).first_or_create
        if tv.tweet_is_valid?(row[0])
          pt.available!
        else
          pt.unavailable!
        end
        new_percentage = 100*i/total_count.ceil
        if prev_percentage < new_percentage
          prev_percentage = new_percentage
          ActionCable.server.broadcast("job_notification:#{user_id}", record_id: project_id, record_type: 'public-tweets', job_type: "progress", progress: new_percentage)
        end
      end
      # End progress
      ActionCable.server.broadcast("job_notification:#{user_id}", record_id: project_id, record_type: 'public-tweets', job_type: "progress", progress: 100)
    end
  end
end
