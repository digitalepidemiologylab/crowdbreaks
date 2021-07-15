class StatusMailer
  include ActionView::Helpers
  include ActionView::Context

  def initialize(type: 'weekly')
    @type = type
    @api = AwsApi.new
    @mailer = ApplicationMailer.new
    if @type == 'weekly'
      @to_email = ENV['EMAIL_STREAM_STATUS_WEEKLY']
      @date_range = 1.week.ago.utc..Time.now.utc
    else
      @to_email = ENV['EMAIL_STREAM_STATUS_DAILY']
      @date_range = 1.day.ago.utc..Time.now.utc
    end
  end

  def send
    return unless send_emails?
    # Get streaming status from API
    options = {
      subject: subject,
      from_name: 'Crowdbreaks',
      from_email: 'no-reply@crowdbreaks.org',
      email: @to_email,
      html: html_email,
    }
    @mailer.send_raw(options)
  end

  def html_email
    content_tag :html do
      content_tag :body do
        concat header
        concat annotation_status
        concat stream_status.html_safe
      end
    end
  end

  def header
    capture do
      concat tag.h1 'Crowdbreaks status update'
      concat "Date: #{Time.current.to_date}"
    end
  end

  def annotation_status
    type = @type == 'weekly' ? 'This week' : 'Today'
    content_tag :div, style: 'white-space: pre;' do
      concat tag.h2 'Annotations'
      concat tag.h3 'Summary'
      concat annotation_summary
      concat tag.br
      concat tag.h3 type
      concat counts_by_project
      concat tag.h3 'All time'
      concat counts_by_project(total: true)
    end
  end

  def annotation_summary
    align = ['left', 'right']
    table do
      concat table_row("Total annotations:", num(annotation_counts), align: align)
      concat table_row("Annotations #{@type == 'weekly' ? 'this week' : 'today'}:", num(annotation_counts(date_range: @date_range)), align: align)
      concat table_row("New users #{@type == 'weekly' ? 'this week' : 'today'}:", num(sign_up_counts(date_range: @date_range)), align: align)
    end
  end

  def counts_by_project(total: false)
    align = ['left'] + ['right']*4
    modes = ['public', 'local', 'mturk', 'all']
    date_range = @date_range unless total
    table(header: ['Project', "Public", "Local", "Mturk", "Total"]) do
      Project.primary.each do |primary_project|
        projects = primary_project.question_sequences
        counts = {}
        modes.each do |mode|
          counts[mode] = 0
          projects.each do |project|
            counts[mode] += annotation_counts(date_range: date_range, mode: mode, results: project.results)
          end
          counts[mode] = num(counts[mode])
        end
        concat table_row(primary_project.name, *counts.values_at(*modes), align: align)
      end
    end
  end

  def annotation_counts(mode: 'all', results: nil, date_range: nil)
    results = Result.all if results.nil?
    if date_range.present?
      results = results.where(created_at: date_range)
    end
    if mode == 'all'
      results.num_annotations
    elsif mode == 'public'
      results.num_public_annotations
    elsif mode == 'mturk'
      results.num_mturk_annotations
    elsif mode == 'local'
      results.num_local_annotations
    else
      raise 'Unsupported mode'
    end
  end

  def sign_up_counts(date_range: nil)
    User.where(created_at: date_range).count
  end

  def stream_status
    @api.get_streaming_email_status(type: @type).strip
  end

  def send_emails?
    ENV['SEND_STATUS_EMAILS'] == 'true'
  end

  def subject
    "Crowdbreaks #{@type} update"
  end

  private

  # html helpers

  def num(num)
    number_with_delimiter(num, delimiter: ',')
  end

  def table(num_cols: 2, header: nil)
    header = ['']*num_cols if header.nil?
    content_tag :table do
      concat table_row(*header, style: 'bold')
      yield
    end
  end

  def table_row(*args, style: '', align: nil)
    align = ['left']*args.length if align.nil?
    content_tag :tr do
      args.each_with_index do |arg, i|
        if style == 'bold'
          concat tag.td(tag.b arg, align: align[i], style: 'padding:0 5px 0 5px;')
        else
          concat tag.td(arg, align: align[i], style: 'padding:0 5px 0 5px;')
        end
      end
    end
  end
end
