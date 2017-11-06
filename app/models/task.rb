class Task < ApplicationRecord
  belongs_to :mturk_batch_job

  enum lifecycle_status: [:unsubmitted, :submitted, :reviewable, :disposed, :accepted]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    reviewable: 'label-info',
    disposed: 'label-danger',
    accepted: 'label-success'
  }

  def submit_job(requester, props)
    result = requester.createHIT(props)
    if result[:HITTypeId].present?
      self.hit_id = result[:HITId]
      self.time_submitted = Time.now
      self.lifecycle_status = :submitted
      self.hittype_id = result[:HITTypeId]
      puts "Find HIT at: https://workersandbox.mturk.com/mturk/preview?groupId=#{result[:HITTypeId]} hit_id: #{self.hit_id}"
      self.save!
      true
    else
      false
    end
  end
end
