class StatusMailerJob < ApplicationJob
  queue_as :low

  def perform(type: 'weekly')
    status_mailer = StatusMailer.new(type: type)
    status_mailer.send
  end
end
