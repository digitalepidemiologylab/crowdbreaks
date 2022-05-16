class CreateTasksJob < ApplicationJob
  queue_as :default

  before_perform do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    mturk_batch_job.update_attribute(:processing, true) if mturk_batch_job.present?
  end

  after_perform do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    mturk_batch_job.update_attribute(:processing, false) if mturk_batch_job.present?
  end

  def perform(mturk_batch_job_id, tweet_rows, destroy_first: false)
    mturk_batch_job = MturkBatchJob.find_by(id: mturk_batch_job_id)
    return unless mturk_batch_job.present?

    if destroy_first
      mturk_batch_job.cleanup
      mturk_batch_job.tasks.delete_all
      mturk_batch_job.mturk_tweets.delete_all
    end
    return unless tweet_rows.count.positive?

    tweet_rows.each do |row|
      mt = MturkTweet.create(
        tweet_id: row[0], tweet_text: row.length == 1 ? '' : row[1], mturk_batch_job_id: mturk_batch_job_id
      )
      if mturk_batch_job.check_availability_before? || mturk_batch_job.check_availability_before_and_after?
        if TweetValidation.tweet_is_valid?(row[0])
          mt.available!
          create_tasks(mturk_batch_job_id, mturk_batch_job.number_of_assignments.to_i)
        else
          mt.unavailable!
        end
      else
        create_tasks(mturk_batch_job_id, mturk_batch_job.number_of_assignments.to_i)
      end
    end
  end

  def create_tasks(mturk_batch_job_id, num_tasks)
    num_tasks.times do
      Task.create(lifecycle_status: :unsubmitted, mturk_batch_job_id: mturk_batch_job_id)
    end
  end
end
