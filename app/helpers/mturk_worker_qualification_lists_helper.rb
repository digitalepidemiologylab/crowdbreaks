module MturkWorkerQualificationListsHelper
  def qual_list_status(status)
    case status
    when 'default'
      image_tag('running.svg') + ' ready'
    when 'updating', 'deleting'
      tag.i(class: 'fa fa-refresh') + ' ' + status
    else
      image_tag('not-running.svg') + ' ' + status
    end
  end

  def get_exit_path
    if current_or_guest_user.admin? or current_or_guest_user.collaborator?
      return manage_local_batch_jobs_path
    else
      return root_path
    end
  end
end
