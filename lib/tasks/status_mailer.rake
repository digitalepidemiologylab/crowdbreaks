desc "Send status email update"
namespace :status_mailer do
  task :weekly => :environment do
    StatusMailerJob.perform_later(type: 'weekly')
  end

  task :daily => :environment do
    StatusMailerJob.perform_later(type: 'daily')
  end
end
