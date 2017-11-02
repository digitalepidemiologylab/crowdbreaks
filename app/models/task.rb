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
end
