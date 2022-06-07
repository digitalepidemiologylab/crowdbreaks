module ApplicationHelper
  def open_csv(csv_file)
    csv_stringio = if csv_file.instance_of?(StringIO)
                     csv_file
                   elsif csv_file.instance_of?(String)
                     File.open(csv_file, 'r')
                   elsif csv_file.instance_of?(ActionDispatch::Http::UploadedFile)
                     File.open(csv_file.path, 'r')
                   end
    CSV.new(csv_stringio)
  end

  def flash_messages
    # Bootstrap notifications
    flash.each do |msg_type, message|
      msg_type = 'success' if msg_type == 'notice'
      msg_type = 'danger' if msg_type == 'alert'
      concat(content_tag(:div, message, class: "alert alert-#{msg_type} alert-dismissible fade show", role: 'alert') do
        concat message
        concat content_tag(
          :button, '&times;'.html_safe, class: 'close', data: { dismiss: 'alert' }, aria: { label: 'Close' }
        )
      end)
    end
    nil
  end

  def toastr_flash_class(type)
    # Mapping for toastr notifications
    case type
    when 'alert'
      'toastr.error'
    when 'notice'
      'toastr.success'
    else
      'toastr.info'
    end
  end

  def title(page_title)
    content_for :title, "Crowdbreaks | #{page_title}"
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

  def availability_status(status)
    case status
    when 'unknown'
      tag.span(status, class: 'badge badge-light')
    when 'available'
      tag.span(status, class: 'badge badge-success')
    else
      tag.span(status, class: 'badge badge-danger')
    end
  end

  def mturk_worker_status(status)
    case status
    when 'default'
      tag.span(status, class: 'badge badge-light')
    when 'blacklisted'
      tag.span(status, class: 'badge badge-warning')
    else
      tag.span(status, class: 'badge badge-danger')
    end
  end

  def endpoint_status(status)
    case status
    when 'InService'
      tag.span(status, class: 'badge badge-success')
    when 'Failed'
      tag.span(status, class: 'badge badge-danger')
    else
      tag.span(status, class: 'badge badge-warning')
    end
  end

  def status_badge(label, type)
    tag.span(label, class: "badge badge-#{type}")
  end

  def link_to_tweet(tweet_id)
    link_to tweet_id.to_s, 'https://twitter.com/user/status/' + tweet_id.to_s, target: '_blank'
  end

  def num(num)
    number_with_delimiter(num, delimiter: "\u202F").html_safe
  end

  def simple_toggle_switch(checked, label, class_name, color: nil)
    content_tag :div do
      content_tag :label, class: 'switch' do
        concat tag.input(type: 'checkbox', checked: checked, class: class_name)
        concat tag.span(class: "slider round#{color.nil? ? '' : " slider-#{color}"}")
        concat tag.span(label, class: 'switch-label')
      end
    end
  end

  def toggle_switch(instance_var, label, model_name, field_name, color: nil, hint: nil)
    class_name = hint.nil? ? '' : 'input field_with_hint'
    name = "#{model_name}[#{field_name}]"
    content_tag :div, class: class_name do
      output = content_tag :label, class: 'switch' do
        concat hidden_field_tag(name, value='0')
        concat check_box_tag(name, value='1', checked=instance_var, class: name)
        concat tag.span(class: "slider round#{color.nil? ? '' : " slider-#{color}"}")
        concat tag.span(label, class: 'switch-label')
      end
      if hint.nil?
        output
      else
        output += tag.p(hint, class: 'help-block')
      end
    end
  end

  def table_row(label, value, h4_tag: true)
    content_tag :tr do
      if h4_tag
        concat tag.td tag.h4 label
      else
        concat tag.td tag.div label
      end
      concat content_tag :td, value, {align: 'right'}
    end
  end

  def go_back_btn(path, col: 'col-12', center: false, mb: 'mb-5')
    content_tag :div, class: "row #{center ? 'justify-content-center' : ''} #{mb}" do
      content_tag :div, class: col do
        link_to path, class: 'btn btn-secondary btn-lg' do
          t 'helpers.go_back'
        end
      end
    end
  end

  def attributes_table(record, mb: 'mb-4', center: true, col: 'col-md-8')
    content_tag :div, class: "row #{center ? 'justify-content-center' : ''} #{mb}" do
      content_tag :div, class: col.to_s do
        content_tag :table, class: 'table vertical-align' do
          concat tag.col
          concat tag.col
          record.attributes.each do |key, val|
            concat table_row(key, val)
          end
        end
      end
    end
  end

  def time_ago(time_at)
    return unless time_at.respond_to?(:strftime)

    tag.div(time_at.iso8601, class: 'convert-by-moment', data: { lang: I18n.locale })
  end

  def _progress_circle_outer
    content_tag :div, class: 'circle' do
      concat content_tag(:div, '<div class="fill"></div>', { class: 'mask full' }, false)
      concat content_tag :div, '<div class="fill"></div><div class="fill fix"></div>', { class: 'mask half' }, false
    end
  end

  def progress_circle(id, small: false, progress: 0, visible: false)
    content_tag :div, **{
      id: id,
      class: (small ? 'progress-circle-sm' : 'progress-circle').to_s,
      data: { progress: progress }, style: visible ? '' : 'display:none;'
    } do
      concat _progress_circle_outer
      concat tag.div class: 'inset'
    end
  end
end
