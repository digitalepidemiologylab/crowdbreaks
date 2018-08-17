require 'csv'

class CreateTasksJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    return unless mturk_batch_job.present?
    mturk_batch_job.update_attribute(:processing, true)
  end

  after_perform do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    return unless mturk_batch_job.present?
    mturk_batch_job.update_attribute(:processing, false)
  end

  def perform(mturk_batch_job_id, tweet_ids, destroy_first: false)
    mturk_batch_job = MturkBatchJob.find_by(id: mturk_batch_job_id)
    return unless mturk_batch_job.present?

    if destroy_first
      mturk_batch_job.cleanup
    end

    tweet_ids.each do |tweet_id|
      MturkTweet.create(tweet_id: tweet_id, mturk_batch_job_id: mturk_batch_job_id)
      mturk_batch_job.number_of_assignments.to_i.times do 
        Task.create(lifecycle_status: :unsubmitted, mturk_batch_job_id: mturk_batch_job_id)
      end
    end
  end
end
