module ResultsHelper
  def result_type(result)
    if result.task.present?
      # mturk batch job result
      tag.span('Mturk', class: 'badge badge-light')
    elsif result.local_batch_job.present?
      # local batch job
      tag.span('local',class:  'badge badge-secondary')
    else
      # public result
      tag.span('public', class: 'badge badge-primary')
    end
  end

  def link_to_user_profile(user)
    if user.present?
      if can? :read, user
        link_to user.username, admin_user_path(user)
      else
        user&.username
      end
    end
  end
end
