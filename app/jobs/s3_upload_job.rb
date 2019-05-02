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
    # Upload files
    sync_s3 = SyncS3.new
    successful = sync_s3.upload_by_id(type, record_id)
    if successful
      ActionCable.server.broadcast("job_notification:#{user_id}", record_id: record_id, job_status: 'completed', job_type: "#{type}_s3_upload", message: 'Upload finished.')
    else
      ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'failed', record_id: record_id, job_type: "#{type}_s3_upload")
    end
    # Ger rid of key
    Rails.cache.delete(cache_key)
  end
end
