class S3UploadJob < ApplicationJob
  queue_as :default

  def perform(type, record_id, user_id)
    # check if same job is already running
    cache_key = "#{type}_s3_upload_#{record_id.to_s}_running"
    if Rails.cache.exist?(cache_key)
      # Another background job is already running, exit
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'failed', record_id: record_id, job_type: "#{type}_s3_upload")
      return
    end
    Rails.cache.write(cache_key, 1, expires_in: 3.minutes)
    case type
    when 'mturk-batch-job-results'
      record = MturkBatchJob.find(record_id)
      tmp_file_path = record.results_to_csv
      s3_key = record.csv_path(type, record.results)
    when 'mturk-batch-job-tweets'
      record = MturkBatchJob.find(record_id)
      tmp_file_path = record.to_csv(record.mturk_tweets, ['tweet_id', 'tweet_text', 'availability'])
      s3_key = record.csv_path(type, record.mturk_tweets)
    when 'local-batch-job-results'
      record = LocalBatchJob.find(record_id)
      tmp_file_path = record.results_to_csv
      s3_key = record.csv_path(type, record.results)
    when 'local-batch-job-tweets'
      record = LocalBatchJob.find(record_id)
      tmp_file_path = record.to_csv(record.local_tweets, ['tweet_id', 'tweet_text', 'availability'])
      s3_key = record.csv_path(type, record.local_tweets)
    else
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'failed', record_id: record_id, job_type: "#{type}_s3_upload")
      Rails.logger.error("Upload type #{type} was not recognized.")
      return
    end

    # upload to s3
    s3 = AwsS3.new
    s3.upload_file(tmp_file_path, s3_key)

    # Get rid of tmp file
    File.delete(tmp_file_path)

    # Ger rid of key
    Rails.cache.delete(cache_key)
    ActionCable.server.broadcast("job_notification:#{user_id}", record_id: record_id, job_status: 'completed', job_type: "#{type}_s3_upload", message: 'Upload finished.')
  end
end
