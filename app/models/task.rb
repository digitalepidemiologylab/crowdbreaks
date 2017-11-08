class Task < ApplicationRecord
  belongs_to :mturk_batch_job
  has_many :results

  enum lifecycle_status: [:unsubmitted, :submitted, :reviewable, :disposed, :accepted]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    reviewable: 'label-info',
    disposed: 'label-danger',
    accepted: 'label-success'
  }

  def submit_job(requester, props)
    # add task id to props for tracking purposes
    props[:RequesterAnnotation] = self.id.to_s

    # Create HIT
    result = requester.createHIT(props)
    if result[:HITTypeId].present?
      self.hit_id = result[:HITId]
      self.time_submitted = Time.now
      self.lifecycle_status = :submitted
      self.hittype_id = result[:HITTypeId]
      self.save!
      true
    else
      false
    end
  end
end
