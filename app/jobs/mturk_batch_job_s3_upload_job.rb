class MturkBatchJobS3UploadJob < ApplicationJob
  queue_as :default

  def perform(mturk_batch_job_id, user_id)
    # check if same job is already running
    cache_key = "mturk_batch_job_s3_upload_#{mturk_batch_job_id}_running"
    if Rails.cache.exist?(cache_key)
      # Another background job is already running, exit
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'failed', job_type: 'mturk_batch_job_s3_upload')
      return
    end
    Rails.cache.write(cache_key, 1, expires_in: 3.minutes)

    mturk_batch_job = MturkBatchJob.find(mturk_batch_job_id)
    s3 = AwsS3.new
    csv_data = mturk_batch_job.to_csv
    s3.put(csv_data, mturk_batch_job.csv_file_path)

    # Ger rid of key
    Rails.cache.delete(cache_key)
    ActionCable.server.broadcast("job_notification:#{user_id}", mturk_batch_job_id: mturk_batch_job_id, job_status: 'completed', job_type: 'mturk_batch_job_s3_upload', message: 'Upload finished.')
  end
end
