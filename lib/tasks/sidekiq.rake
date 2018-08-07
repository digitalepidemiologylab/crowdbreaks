require 'sidekiq/api'

namespace :sidekiq do
  desc "Clear all jobs from sidekiq queues"
  task clear: :environment do
    # Clear retry set
    Sidekiq::RetrySet.new.clear

    # Clear scheduled jobs 
    Sidekiq::ScheduledSet.new.clear

    # Clear 'Dead' jobs statistics
    Sidekiq::DeadSet.new.clear
  end

end
