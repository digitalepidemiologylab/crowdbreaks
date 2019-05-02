desc "Check whether all systems are running"
namespace :sync_s3 do
  task :run => :environment do
    SyncS3Job.perform_later
  end
end


