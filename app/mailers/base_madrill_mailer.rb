class BaseMandrillMailer < ActionMailer::Base
  default(
    from: "hello@example.com",
    reply_to: "hello@example.com"
  )

  private

  def send_mail(email, subject, body)
    mail(to: email, subject: subject, body: body, content_type: "text/html")
  end

  def mandrill_template(template_name, attributes)
    merge_vars = attributes.map do |key, value|
      { name: key, content: value }
    end

    Crowdbreaks::Mandrill.templates.render(template_name, [], merge_vars)["html"]
  end
end
