desc "Sync all S3 data"
namespace :sync_s3 do
  task :run => :environment do
    SyncS3Job.perform_later
  end
end
