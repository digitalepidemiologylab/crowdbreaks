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

  def update_after_hit_submit(hit_id, time_submitted)
    self.update_attributes!({
      time_submitted: time_submitted,
      lifecycle_status: :submitted,
    })
  end

  def hit
    if hit_id.present?
      Mturk.new(sandbox: mturk_batch_job.sandbox).get_hit(hit_id)
    end
  end

  def hit_review_status
    hit.try(:hit_review_status)
  end

  def hit_status
    hit.try(:hit_status)
  end

  def delete_hit
    if hit_id.present?
      Mturk.new(sandbox: mturk_batch_job.sandbox).delete_hit(hit_id)
    end
  end
end
