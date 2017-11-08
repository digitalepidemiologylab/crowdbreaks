module MturkBatchJobsHelper
  def status(mturk_batch_job)
    status_labels = {
      unsubmitted: 'label-default',
      submitted: 'label-primary',
      completed: 'label-success'
    }
    status = mturk_batch_job.status
    content_tag(:div, status.to_s, class: 'label '+status_labels[status])
  end

  def completed_by_total(mturk_batch_job)
    "#{mturk_batch_job.num_tasks_completed}/#{mturk_batch_job.num_tasks}"
  end
end
