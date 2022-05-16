class CreatePublicTweetsJob < ApplicationJob
  queue_as :default

  # Creates <tt>PublicTweet</tt> objects linked to the <tt>project_id</tt> for the given <tt>tweet_rows</tt>
  # (extracted previously from a CSV file which is uploaded to the <tt>Project</tt> form)
  def perform(project_id, user_id, tweet_rows, destroy_first: false)
    project = Project.find_by(id: project_id)
    return unless project.present?

    if destroy_first
      project.public_tweets.find_each do |public_tweet|
        public_tweet.destroy! unless Result.exists?(tweet_id: public_tweet.tweet_id)
      end
    end

    total_count = tweet_rows.count
    return unless total_count.positive?

    pn = ProgressNotifier.new(projct_id, user_id, 'public-tweets', total_count)
    pn.start
    tweet_rows.each_with_index do |row, i|
      pt = PublicTweet.where(tweet_id: row[0], tweet_text: row.length == 1 ? '' : row[1], project: project).first_or_create
      if TweetValidation.tweet_is_valid?(row[0])
        pt.available!
      else
        pt.unavailable!
      end
      pn.update(i)
    end
    pn.finish
  end
end
