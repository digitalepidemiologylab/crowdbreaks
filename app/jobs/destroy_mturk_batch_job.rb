class DestroyMturkBatchJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    mturk_batch_job = MturkBatchJob.find_by(id: job.arguments.first)
    return unless mturk_batch_job.present?
    mturk_batch_job.update_attribute(:marked_for_deletion, true)
  end

  def perform(mturk_batch_job_id, destroy_results: false)
    mturk_batch_job = MturkBatchJob.find_by(id: mturk_batch_job_id)
    return unless mturk_batch_job.present?
    mturk_batch_job.cleanup(destroy_results: destroy_results)
    mturk_batch_job.remove_qualification
    mturk_batch_job.destroy
  end
end
