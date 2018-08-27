module ResultsHelper
  def result_type(type)
    case type
    when 'public'
      # public result
      tag.span('public', class: 'badge badge-primary')
    when 'local'
      # local batch job
      tag.span('local',class:  'badge badge-secondary')
    when 'mturk'
      # mturk batch job
      tag.span('Mturk', class: 'badge badge-light')
    else
      # public result
      tag.span('unknown', class: 'badge')
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
