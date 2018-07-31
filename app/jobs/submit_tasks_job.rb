class SubmitTasksJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    Rails.logger.error "[#{self.class.name}] #{exception.to_s}"   
  end

  after_enqueue do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    mturk_batch_job.update_attribute(:processing, true)
  end

  after_perform do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    mturk_batch_job.update_attribute(:processing, false)
  end

  def perform(mturk_batch_job_id)
    mturk_batch_job = MturkBatchJob.find_by(id: mturk_batch_job_id)

    mturk = Mturk.new(sandbox: mturk_batch_job.sandbox)

    # create new HIT type for this batch
    hittype_id = mturk.create_hit_type(mturk_batch_job)
    mturk_batch_job.update_attribute(:hittype_id, hittype_id)

    # create hit given that HIT type
    mturk_batch_job.tasks.each do |t|
      hit = mturk.create_hit_with_hit_type(t.id, hittype_id, mturk_batch_job)
      t.update_attributes({
        hit_id: hit.hit_id,
        time_submitted: hit.creation_time,
        lifecycle_status: :submitted,
      })
    end
  end
end
