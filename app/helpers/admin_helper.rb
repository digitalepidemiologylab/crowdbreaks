module AdminHelper
  def admin_link_class(target_controller_name)
    css_classes = 'btn nav-admin-link'
    if controller_name == target_controller_name
      css_classes += ' btn-primary'
    else
      css_classes += ' btn-secondary'
    end
    css_classes
  end
end
