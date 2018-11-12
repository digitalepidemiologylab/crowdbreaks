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

  def answer_btn(answer, color)
    predefined_btn_types = ['btn-primary', 'btn-secondary', 'btn-positive', 'btn-negative']
    class_name = 'btn'
    style = ''
    if predefined_btn_types.include?(color)
      class_name += " #{color}"
    else
      style += "background-color:#{color};"
    end
    tag.button answer, class: class_name, style: style
  end
end
