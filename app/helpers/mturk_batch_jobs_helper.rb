module MturkBatchJobsHelper
  def status(status)
    case status
    when 'completed'
      image_tag('running.svg') + ' ' + status
    when 'processing'
      image_tag('paused.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end
end
