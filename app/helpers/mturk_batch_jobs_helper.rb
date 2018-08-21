module MturkBatchJobsHelper
  def status(status)
    case status
    when 'completed'
      image_tag('running.svg') + ' ' + status
    when 'processing', 'deleting'
      tag.i(class: 'fa fa-refresh') + ' ' + status
    when 'in progress'
      image_tag('paused.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end

  def mturk_url(hittype_id, sandbox)
    sandbox_url = sandbox ? 'workersandbox' : 'www'
    "https://#{sandbox_url}.mturk.com/mturk/preview?groupId=#{hittype_id}"
  end
end
