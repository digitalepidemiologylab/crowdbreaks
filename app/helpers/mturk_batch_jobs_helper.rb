module MturkBatchJobsHelper
  def status(status)
    case status
    when 'completed'
      image_tag('running.svg') + ' ' + status
    when 'submitted'
      image_tag('paused.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end

  def completed_by_total(mturk_batch_job)
    "#{mturk_batch_job.num_tasks_completed}/#{mturk_batch_job.num_tasks}"
  end
end
