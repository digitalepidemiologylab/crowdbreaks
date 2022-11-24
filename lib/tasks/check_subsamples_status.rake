desc 'Check whether there are new evaluation subsample files'
task check_subsamples_status: :environment do
  Rails.logger = Logger.new($stdout) if defined?(Rails) && (Rails.env == 'development')
  api = AwsApi.new

  Project.where(auto_mturking: true, primary: true).each do |project|
    response = api.check_subsamples_status(project.name)
    Rails.logger.error(response.message) and next if response.error?

    s3_objs = response.body
    s3_objs.each do |s3_attrs|
      begin
        mturk_batch_job = MturkBatchJob.find_by_name(attrs.delete(:mturk_batch_name))
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("#{e.class} (#{e.message})")
        next
      end
      create_auto_local_batch_job(mturk_batch_job, s3_attrs)
    end
  end
end

def create_auto_local_batch_job(mturk_batch_job, s3_attrs)
  admins = User.where(role: 'super_admin')
  mturk_auto_batch = MturkAutoBatch.where(mturk_batch_job: mturk_batch_job).first
  local_batch_job = LocalBatchJob.create!(
    { project_id: mturk_batch_job.project.id, name: "evaluate_#{mturk_batch_job.name}",
      instructions: "Evaluate auto MTurk batch '#{mturk_batch_name}'", user_ids: admins.ids, auto: true,
      mturk_auto_batch: mturk_auto_batch, **s3_attrs }
  )

  # Generate tasks
  # 28.04.2022: Here I don't understand why ProgressNotifier is needed (in perform_later), and what a user has to do
  # with it, so I just take a first admin to fill it in.
  CreateLocalTweetsJob.perform_later(local_batch_job.id, admins[0].id, local_batch_job.retrieve_tweet_rows)
end
