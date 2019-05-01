desc "Check whether all systems are running"
namespace :sync_s3 do
  task :run => :environment do
    sync_s3 = SyncS3.new
    if sync_s3.run
      Rails.logger.info "Successfully synced S3 files"
    else
      Rails.logger.error "Something went wrong when syncing S3 files"
    end
  end
end


