desc "Check whether 'other/csv/automatic-samples/status.json' has been updated"
task check_samples_status: :environment do
  include MturkAutoHelper
  Rails.logger = Logger.new($stdout) if defined?(Rails) && (Rails.env == 'development')
  api = AwsApi.new

  Project.where(auto_mturking: true, primary: true).each do |project|
    response = api.check_samples_status(project.name)
    Rails.logger.error(response.message) and next if response.error?

    primary_job = PrimaryMturkBatchJob.find_by(project_id: project.id)
    mturk_batch_job_clone = primary_job&.mturk_batch_job
    Rails.logger.info("No primary job set for project '#{project.name}'.") and next if mturk_batch_job_clone.nil?

    s3_objs = response.body
    s3_objs.each do |s3_attrs|
      new_attributes = new_attributes(mturk_batch_job, primary_job, s3_attrs)
      create_auto_mturk_batch_job(new_attributes)
    end
  end

  def cloned_attributes
    mturk_batch_job_clone.attributes.select do |a|
      %w[name project_id description title keywords reward lifetime_in_seconds auto_approval_delay_in_seconds
         assignment_duration_in_seconds instructions number_of_assignments minimal_approval_rate max_tasks_per_worker
         exclude_blacklisted check_availability min_num_hits_approved delay_start delay_next_question sandbox].include?(a)
    end
  end

  def new_attributes(mturk_batch_job, primary_job, s3_attrs)
    hex = SecureRandom.hex
    { name: "#{mturk_batch_job.name}_auto_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{hex[0..5]}",
      cloned_name: mturk_batch_job.name, title: "#{mturk_batch_job.title} [#{hex[0..5]}]", auto: true,
      mturk_worker_qualification_list_id: primary_job.mturk_worker_qualification_list&.id,
      max_tasks_per_worker: primary_job.max_tasks_per_worker, **s3_attrs }
  end

  def create_auto_mturk_batch_job(new_attributes)
    mturk_batch_job = MturkBatchJob.new(cloned_attributes.merge(new_attributes))
    mturk_auto_batch = MturkAutoBatch.create!({ mturk_batch_job: mturk_batch_job })

    ActiveRecord::Base.transaction do
      mturk_batch_job.save!
      mturk_auto_batch.save!
    end

    # Generate tasks
    CreateTasksJob.perform_later(mturk_batch_job.id, mturk_batch_job.retrieve_tweet_rows)
  end
end
