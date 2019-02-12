class SubmitTasksJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    ErrorLogger.error "[#{self.class.name}] #{exception.to_s}"   
  end

  after_enqueue do |job|
    mturk_batch_job = MturkBatchJob.find(job.arguments.first)
    mturk_batch_job.update_attribute(:processing, true)
  end

  after_perform do |job|
    mturk_batch_job = MturkBatchJob.find(job.arguments.first)
    mturk_batch_job.update_attribute(:processing, false)
  end

  def perform(mturk_batch_job_id)
    mturk_batch_job = MturkBatchJob.find(mturk_batch_job_id)
    mturk = Mturk.new(sandbox: mturk_batch_job.sandbox)

    # create new HIT type for this batch
    hittype_id, qualification_type_id = mturk.create_hit_type(mturk_batch_job)
    if hittype_id.nil? or qualification_type_id.nil?
      ErrorLogger.error "Something went wrong when creating HIT type. Aborting" and return
    end
    Rails.logger.info "HIT type: #{hittype_id}, qualification type: #{qualification_type_id}"
    mturk_batch_job.update_attributes!({
      hittype_id: hittype_id,
      qualification_type_id: qualification_type_id
    })

    # exclude blacklisted workers
    if mturk_batch_job.exclude_blacklisted? and not mturk_batch_job.sandbox?
      Rails.logger.info "Excluding blacklisted workers from qualification"
      sleep 10 unless Rails.env.test?  # small wait for the qualification type to be created on Amazon properly
      mturk_batch_job.exclude_blacklisted_workers
    end

    # number of HITs to be generated
    if mturk_batch_job.check_availability_before? or mturk_batch_job.check_availability_before_and_after?
      num_hits = mturk_batch_job.mturk_tweets.available.count * mturk_batch_job.number_of_assignments
    else
      num_hits = mturk_batch_job.tasks.count
    end
    mturk_batch_job.tasks.each_with_index do |t, ix|
      if ix >= num_hits
        # exceeded num_his - get rid of remaining tasks
        t.destroy
      end
      # create hit given that HIT type
      hit = mturk.create_hit_with_hit_type(t.id, hittype_id, mturk_batch_job)
      t.update_attributes!({
        hit_id: hit.hit_id
      })
      t.update_after_hit_submit(hit.creation_time)
    end
  end
end
