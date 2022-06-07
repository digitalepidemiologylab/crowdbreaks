desc 'Check whether there are new evaluation subsample files on a given day'
task check_subsamples_status: :environment do
  Rails.logger = Logger.new($stdout) if defined?(Rails) && (Rails.env == 'development')
  api = AwsApi.new

  Project.where(auto_mturking: true, primary: true).each do |project|
    response = api.check_subsamples_status(project.name)
    if response.error?
      Rails.logger.error(response.message)
      next
    elsif response.fail?
      Rails.logger.warning(response.message)
    end

    mturk_batch_name, tweets = response.body
    Rails.logger.info(mturk_batch_name)
    Rails.logger.info(tweets)

    begin
      mturk_batch_job = MturkBatchJob.find_by_name(mturk_batch_name)
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("#{e.class} (#{e.message})")
      next
    end
    admins = User.where(role: 'super_admin')
    local_batch_job_attributes = {
      project_id: mturk_batch_job.project.id, name: "evaluate_#{mturk_batch_name}",
      instructions: "Evaluate auto MTurk batch '#{mturk_batch_name}'",
      user_ids: admins.ids, auto: true
    }
    local_batch_job = LocalBatchJob.new(local_batch_job_attributes)
    local_batch_job.job_file = tweets

    mturk_auto_batch = MturkAutoBatch.where(mturk_batch_job: mturk_batch_job).first
    local_batch_job.mturk_auto_batch = mturk_auto_batch

    local_batch_job.save!

    # Generate tasks
    # 28.04.2022: Here I don't understand why ProgressNotifier is needed (in perform_later), and what a user has to do
    # with it, so I just take a first admin to fill it in.
    CreateLocalTweetsJob.perform_later(local_batch_job.id, admins[0].id, local_batch_job.retrieve_tweet_rows)
  end
end
