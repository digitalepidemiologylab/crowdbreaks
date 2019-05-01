class SyncS3

  def initialize
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
  end

  def run
    t_start = Time.now
    Rails.logger.info "Syncing MturkBatchJobs"
    sync_mturk_batch_jobs
    Rails.logger.info "Syncing LocalBatchJobs"
    sync_local_batch_jobs
    t_end = Time.now
    Rails.logger.info "Finished in #{(t_end - t_start).to_i/60.0} minutes"
  end


  def sync_mturk_batch_jobs
    MturkBatchJob.find_each do |mturk_batch_job|
      if mturk_batch_job.results.any? 
        S3UploadJob.perform_now('mturk-batch-job-results', mturk_batch_job.id, 0)
      end
      if mturk_batch_job.mturk_tweets.any? 
        S3UploadJob.perform_now('mturk-batch-job-tweets', mturk_batch_job.id, 0)
      end
    end
  end

  def sync_local_batch_jobs
    LocalBatchJob.find_each do |local_batch_job|
      if local_batch_job.results.any? 
        S3UploadJob.perform_now('local-batch-job-results', local_batch_job.id, 0)
      end
      if local_batch_job.local_tweets.any? 
        S3UploadJob.perform_now('local-batch-job-tweets', local_batch_job.id, 0)
      end
    end
  end
end
