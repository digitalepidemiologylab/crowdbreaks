desc 'Check whether all systems are running'
namespace :watch_stream do
  task check: :environment do
    watch_stream = WatchStream.new
    next unless watch_stream.should_run?

    if watch_stream.check_all_systems
      Rails.logger.info 'The stream is up and running. Nothing to report.'
    else
      Rails.logger.error 'One or more systems are inactive.'
    end
  end

  task activate: :environment do
    watch_stream = WatchStream.new
    watch_stream.activate
  end
end
