require 'httparty'

class RecaptchaVerification
  include HTTParty

  def verify(response ="")
    resp = self.class.post('https://www.google.com/recaptcha/api/siteverify', query: {secret: ENV['RECAPTCHA_SECRET'], response: response})
    resp.parsed_response
  end
end

