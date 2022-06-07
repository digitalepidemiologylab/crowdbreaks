module UsersHelper
  def role_badge(role)
    case role
    when 'super_admin'
      tag.span(role, class: 'badge badge-dark')
    when 'admin'
      tag.span(role, class: 'badge badge-danger')
    when 'collaborator'
      tag.span(role, class: 'badge badge-warning')
    when 'contributor'
      tag.span(role, class: 'badge badge-primary')
    when 'default'
      tag.span(role, class: 'badge badge-light')
    else
      tag.span(role, class: 'badge badge-light')
    end
  end
end
