module LocalBatchJobsHelper
  def local_batch_job_status(status)
    case status
    when 'ready'
      image_tag('running.svg') + ' ' + status
    when 'processing', 'deleting'
      tag.i(class: 'fa fa-refresh') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end
end
