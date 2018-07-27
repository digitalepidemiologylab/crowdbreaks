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

  def update_after_hit_submit(time_submitted)
    self.update_attributes!({
      time_submitted: time_submitted,
      lifecycle_status: :submitted,
    })
  end
end
