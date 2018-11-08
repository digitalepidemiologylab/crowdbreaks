module ApplicationHelper
  def flash_messages
    flash.each do |msg_type, message|
      msg_type = "success" if msg_type == "notice"
      msg_type = "danger" if msg_type == "alert"
      concat(content_tag(:div, message, class: "alert alert-#{msg_type} alert-dismissible fade show", role: 'alert') do
        concat message
        concat content_tag(:button, '&times;'.html_safe, class: "close", data: { dismiss: 'alert' }, aria: {label: 'Close'})
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

  def status_yes_no(bool_val)
    if bool_val
      tag.span('Yes', class: 'badge badge-success')
    else
      tag.span('No', class: 'badge badge-danger')
    end
  end

  def status_badge(label, type)
    tag.span(label, class: "badge badge-#{type}")
  end

  def link_to_tweet(tweet_id)
    link_to tweet_id.to_s, 'https://twitter.com/statuses/' + tweet_id.to_s, target: '_blank'
  end

  def num(num)
    number_with_delimiter(num, delimiter: '&#x202f;'.html_safe)
  end

  def toggle_switch(instance_var, label, name)
    content_tag :div do
      content_tag :label, class: 'switch' do
        concat check_box_tag(name, 'checkbox', instance_var, class: name) 
        concat tag.span(class: 'slider round')
        concat tag.span(label, class: 'switch-label')
      end
    end
  end

  def table_row(label, value)
    content_tag :tr do
      concat tag.td tag.h4 label
      concat content_tag :td, value, {align: 'right'}
    end
  end

  def go_back_btn(path, col: 'col-12', mb: 'mb-5')
    content_tag :div, class: "row #{mb}" do
      content_tag :div, class: col do
        link_to path, class: 'btn btn-secondary btn-lg' do 
          'Go back'
        end
      end
    end
  end
end
