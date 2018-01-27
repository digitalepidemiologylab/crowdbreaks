module Manage::DashboardHelper
  def label_based_on_status(status)
    if status == 'running' or status == 'paused'
      image_tag(status+'.svg') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end
end
