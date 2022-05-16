class SyncS3
  def initialize
    Rails.logger = Logger.new($stdout) if defined?(Rails) && (Rails.env == 'development')
    @s3 = AwsS3.new
  end

  def run
    t_start = Time.now
    Rails.logger.debug 'Collecting jobs...'
    jobs = collect_jobs
    Rails.logger.debug 'Removing unused files...'
    removable = get_removable(jobs)
    remove(removable)
    Rails.logger.debug 'Uploading non-existant files...'
    upload(jobs)
    t_end = Time.now
    Rails.logger.info "Finished in #{(t_end - t_start).to_i / 60.0} minutes"
  end

  def collect_jobs
    jobs = []
    # mturk
    MturkBatchJob.find_each do |mturk_batch_job|
      if mturk_batch_job.results.any?
        type = 'mturk-batch-job-results'
        s3_key = mturk_batch_job.assoc_s3_key(type, mturk_batch_job.results)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': mturk_batch_job.id, 'exists': exists })
      end
      if mturk_batch_job.mturk_tweets.any?
        type = 'mturk-batch-job-tweets'
        s3_key = mturk_batch_job.assoc_s3_key(type, mturk_batch_job.mturk_tweets)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': mturk_batch_job.id, 'exists': exists })
      end
    end
    # local
    LocalBatchJob.find_each do |local_batch_job|
      if local_batch_job.results.any?
        type = 'local-batch-job-results'
        s3_key = local_batch_job.assoc_s3_key(type, local_batch_job.results)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': local_batch_job.id, 'exists': exists })
      end
      if local_batch_job.local_tweets.any?
        type = 'local-batch-job-tweets'
        s3_key = local_batch_job.assoc_s3_key(type, local_batch_job.local_tweets)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': local_batch_job.id, 'exists': exists })
      end
    end
    Project.find_each do |project|
      # public
      if project.results.public_res_type.any?
        type = 'public-results'
        s3_key = project.assoc_s3_key(type, project.results.public_res_type)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': project.id, 'exists': exists })
      end
      # other
      if project.results.other_res_type.any?
        type = 'other-results'
        s3_key = project.assoc_s3_key(type, project.results.public_res_type)
        exists = @s3.exists?(s3_key)
        jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': project.id, 'exists': exists })
      end
    end
    # projects
    Project.primary.find_each do |project|
      type = 'project'
      s3_key = project.s3_key
      exists = @s3.exists?(s3_key)
      jobs.push({ 's3_key': s3_key, 'type': type, 'record_id': project.id, 'exists': exists })
    end
    jobs
  end

  def get_removable(jobs)
    files_present = @s3.list_dir('other/').to_set
    files_needed = jobs.collect { |j| j[:s3_key] }.to_set
    files_present - files_needed
  end

  def remove(removable)
    removable.each do |s3_key|
      Rails.logger.debug "Removing file #{s3_key}"
      @s3.remove(s3_key)
    end
  end

  def upload(jobs)
    jobs.each do |job|
      unless job[:exists]
        Rails.logger.debug "Uploading file #{job[:s3_key]}"
        upload_by_id(job[:type], job[:record_id], s3_key = job[:s3_key], check_exists = false)
      end
    end
  end

  def upload_by_id(type, record_id, s3_key=nil, check_exists=true)
    case type
    when 'mturk-batch-job-results'
      record = MturkBatchJob.find(record_id)
      s3_key = record.assoc_s3_key(type, record.results) unless s3_key.present?
    when 'mturk-batch-job-tweets'
      record = MturkBatchJob.find(record_id)
      s3_key = record.assoc_s3_key(type, record.mturk_tweets) unless s3_key.present?
    when 'local-batch-job-results'
      record = LocalBatchJob.find(record_id)
      s3_key = record.assoc_s3_key(type, record.results) unless s3_key.present?
    when 'local-batch-job-tweets'
      record = LocalBatchJob.find(record_id)
      s3_key = record.assoc_s3_key(type, record.local_tweets) unless s3_key.present?
    when 'public-results'
      record = Project.find(record_id)
      s3_key = record.assoc_s3_key(type, record.results.public_res_type) unless s3_key.present?
    when 'other-results'
      record = Project.find(record_id)
      s3_key = record.assoc_s3_key(type, record.results.other_res_type) unless s3_key.present?
    when 'project'
      record = Project.find(record_id)
      s3_key = record.s3_key(type, record.results.public_res_type) unless s3_key.present?
    else
      Rails.logger.error("Upload type #{type} was not recognized.")
      return false
    end
    # Check if file already exists
    if check_exists && @s3.exists?(s3_key)
      Rails.logger.info("File #{s3_key} exists already on S3.")
      return true
    end
    # Write local file
    case type
    when 'mturk-batch-job-results', 'local-batch-job-results'
      tmp_file_path = record.results_to_csv
    when 'public-results', 'other-results'
      tmp_file_path = record.results_to_csv(type: type)
    when 'mturk-batch-job-tweets'
      tmp_file_path = record.assoc_dump_to_local(record.mturk_tweets, %w[tweet_id tweet_text availability])
    when 'local-batch-job-tweets'
      tmp_file_path = record.assoc_dump_to_local(record.local_tweets, %w[tweet_id tweet_text availability])
    when 'project'
      tmp_file_path = record.dump_to_local
    end
    # upload local file to s3
    @s3.upload_file(tmp_file_path, s3_key)
    # Get rid of local file
    File.delete(tmp_file_path)
    true
  end
end
