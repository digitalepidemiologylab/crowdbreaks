module ApplicationHelper
  def flash_messages
    flash.each do |msg_type, message|
      msg_type = "success" if msg_type == "notice"
      msg_type = "danger" if msg_type == "alert"
      concat(content_tag(:div, message, class: "alert alert-#{msg_type}") do
        concat content_tag(:button, '&times;'.html_safe, class: "close", data: { dismiss: 'alert' })
        concat message
      end)
    end
    nil
  end

  def title(page_title)
    content_for :title, 'Crowdbreaks | ' + page_title.to_s
  end

  def current_namespace?(namespace)
    controller_path.split('/').first == namespace
  end
end
