module Manage::DashboardHelper
  LABEL_BY_STATUS = {
      'running': 'label-success',
      'dead': 'label-danger',
      'exited': 'label-danger',
      'paused': 'label-warning'
    }

  def label_based_on_status(status)
    if LABEL_BY_STATUS.include?(status.to_sym)
      label = LABEL_BY_STATUS[status.to_sym]
    else
      label = 'label-danger'
    end
  end
end
