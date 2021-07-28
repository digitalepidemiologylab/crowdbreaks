class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@crowdbreaks.org', reply_to: 'no-reply@crowdbreaks.org'

  def send(options = {})
    # check if all required options are present
    verify_options(options)

    # compile message
    message = {
      subject: full_subject(options[:subject]),
      from_name: options.fetch(:from_name, 'Crowdbreaks'),
      from_email: options.fetch(:from_email, 'no-reply@crowdbreaks.org'),
      to: [
        {
          email: options[:email],
          type: 'to'
        }
      ],
      global_merge_vars: options.fetch(:global_merge_vars, [])
    }

    # send template
    if Rails.env.development?
      # Use letter opener to display email in development
      mail(convert_mandrill_message(message)).deliver
    else
      Rails.logger.info('Sending email through Mandrill templates')
      Crowdbreaks::Mandrill.messages.send_template(options[:template], [], message) unless Rails.env.test?
    end
  rescue Mandrill::Error => e
    ErrorLogger.error(e)
    raise e
  end

  def send_raw(options = {})
    message = {
      subject: full_subject(options[:subject]),
      from_name: options.fetch(:from_name, 'Crowdbreaks'),
      from_email: options.fetch(:from_email, 'no-reply@crowdbreaks.org'),
      to: [
        {
          email: options.fetch(:email, 'email@example.com'),
          type: 'to'
        }
      ],
      html: options.fetch(:html, ''),
      text: options.fetch(:text, ''),
    }
    if Rails.env.development?
      # Use letter opener to display email in development
      mail(convert_mandrill_message(message)).deliver
    else
      Rails.logger.info('Sending raw Mandrill email')
      Crowdbreaks::Mandrill.messages.send(message) unless Rails.env.test?
    end
  end

  private

  def full_subject(subject)
    "[Crowdbreaks] #{subject}"
  end

  def verify_options(options, required_keys=%i[template email subject])
    required_keys.each do |key|
      raise "Key #{key} has to be present in options in order to send email!" unless options.key?(key)
    end
  end

  def convert_mandrill_message(message)
    {
      from: message[:from_email],
      to: message[:to].map{ |m| m[:email] }.join(', '),
      subject: message[:subject],
      body: JSON.pretty_generate(message)
    }
  end
end
