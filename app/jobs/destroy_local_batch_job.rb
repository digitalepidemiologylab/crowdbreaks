class DestroyLocalBatchJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    local_batch_job = LocalBatchJob.find_by(id: job.arguments.first)
    local_batch_job.update_attribute(:deleting, true)
  end

  def perform(local_batch_job_id)
    local_batch_job = LocalBatchJob.find_by(id: local_batch_job_id)
    return if local_batch_job.nil?
    local_batch_job.destroy
  end
end
