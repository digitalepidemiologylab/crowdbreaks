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
end
