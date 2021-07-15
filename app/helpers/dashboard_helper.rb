module DashboardHelper
  def label_based_on_status(status)
    status = status.to_s.downcase
    status_to_pic = {
      'running' => 'running', 'active' => 'running',
      'paused' => 'paused', 'creating' => 'paused', 'deleting' => 'paused',
      'true' => 'running'
    }
    if status_to_pic.keys.include?(status)
      image_tag(status_to_pic[status] + '.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end

  def label_up_to_date(status)
    if status
      image_tag('running.svg') + ' Up-to-date'
    else
      image_tag('not-running.svg') + ' Not up-to-date'
    end
  end

  def label_es_health(status)
    case status
    when 'green'
      image_tag('running.svg') + ' ' + status
    when 'yellow'
      image_tag('paused.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end
end
