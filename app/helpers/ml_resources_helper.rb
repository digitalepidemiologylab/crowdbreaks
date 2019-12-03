module MlResourcesHelper
  def endpoint_status(status)
    case status
    when 'InService'
      image_tag('running.svg') + ' ' + status
    when 'Creating', 'Updating', 'Deleting'
      tag.i(class: 'fa fa-refresh') + ' ' + status
    when 'Failed', 'OutOfService'
      image_tag('not-running.svg') + ' ' + status
    else
      image_tag('paused.svg') + ' ' + status
    end
  end
end
