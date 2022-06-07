class MturkAutoBatch < ApplicationRecord
  has_one :mturk_batch_job, dependent: :destroy
  has_one :local_batch_job, dependent: :destroy

  validate :mturk_batch_job_auto_only
  validate :local_batch_job_auto_only

  private

  def mturk_batch_job_auto_only
    return if mturk_batch_job.nil?
    return if mturk_batch_job.auto == true

    errors.add(
      :base,
      'The mturk_batch_job that you are trying to associate with this mturk_auto_batch instance ' \
      'is not an automatically created one.'
    )
  end

  def local_batch_job_auto_only
    return if local_batch_job.nil?
    return if local_batch_job.auto == true

    errors.add(
      :base,
      'The local_batch_job that you are trying to associate with this mturk_auto_batch instance ' \
      'is not an automatically created one.'
    )
  end
end
