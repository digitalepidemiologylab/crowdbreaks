desc "Check whether 'other/csv/automatic-samples/status.json' has been updated"
task check_samples_status: :environment do
  include MturkAutoHelper
  Rails.logger = Logger.new($stdout) if defined?(Rails) && (Rails.env == 'development')
  api = AwsApi.new
  response = api.check_samples_status
  Rails.logger.info(response.message) if response.fail? || response.error?
  exit if response.fail? || response.error?
  project_batches = response.body

  Project.where(auto_mturking: true).each do |project|
    next unless project_batches.include?(project.slug)

    mturk_worker_qualification_list_id = nil
    unless MturkWorkerQualificationList.where(name: "#{project.name}_auto").empty?
      mturk_worker_qualification_list_id = MturkWorkerQualificationList.find_by_name("#{project.name}_auto").id
    end

    mturk_batch_job_clone = PrimaryMturkBatchJob.find_by(project_id: project.id)&.mturk_batch_job
    Rails.logger.info("No primary job set for project '#{project.name}'.") and next if mturk_batch_job_clone.nil?

    cloned_attributes = mturk_batch_job_clone.attributes.select do |a|
      %w[name project_id description title keywords reward lifetime_in_seconds auto_approval_delay_in_seconds
         assignment_duration_in_seconds instructions number_of_assignments minimal_approval_rate max_tasks_per_worker
         exclude_blacklisted check_availability min_num_hits_approved delay_start delay_next_question sandbox].include?(a)
    end

    hex = SecureRandom.hex
    mturk_batch_job = MturkBatchJob.new(cloned_attributes)
    mturk_batch_job.cloned_name = mturk_batch_job.name
    mturk_batch_job.name = "#{mturk_batch_job.name}_auto_#{Time.now.strftime('%Y%m%d%H%M%S')}_#{hex[0..5]}"
    mturk_batch_job.title = "#{mturk_batch_job.title} [#{hex[0..5]}]"
    mturk_batch_job.auto = true
    mturk_batch_job.job_file = project_batches[project.slug]
    mturk_batch_job.mturk_worker_qualification_list_id = mturk_worker_qualification_list_id

    mturk_auto_batch = MturkAutoBatch.new
    mturk_auto_batch.mturk_batch_job = mturk_batch_job
    mturk_auto_batch.save!
    mturk_batch_job.save!

    # Generate tasks
    CreateTasksJob.perform_later(mturk_batch_job.id, mturk_batch_job.retrieve_tweet_rows)
  end
end
