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
      global_merge_vars:  options.fetch(:global_merge_vars, [])
    }

    # send template
    Crowdbreaks::Mandrill.messages.send_template(options[:template], [], message) unless Rails.env.test?
  rescue Mandrill::Error => e
    Rails.logger.debug(e)
    raise e
  end

  private

  def full_subject(subject)
    '[Crowdbreaks] ' + subject
  end

  def verify_options(options, required_keys=[:template, :email, :subject])
    required_keys.each do |key|
      unless options.has_key?(key)
        raise "Key #{key.to_s} has to be present in options in order to send email!"
      end
    end
  end
end
