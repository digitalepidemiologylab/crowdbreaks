namespace :results do
  desc "Removes question sequence duplicates"
  task remove_duplicates_by_worker: :environment do
    # This task removes all duplicates of same question/same tweet/same answer/same mturk_worker_id within a batch
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    batch_name = ENV['batch_name']
    if batch_name.present?
      puts "Selecting results from batch #{batch_name}..."
      results = MturkBatchJob.find_by(name: batch_name).results
    else
      results = Result.all
    end

    query = results.left_outer_joins(:task)
      .select('MAX(results.id) as id', 'tasks.mturk_worker_id as mturk_worker_id', 'count(*) as num_results', :tweet_id, :answer_id, :question_id)
      .group(:tweet_id, 'tasks.mturk_worker_id', :tweet_id, :answer_id, :question_id)

    res_id_duplicates = []
    query.each do |rec|
      if rec.num_results > 1
        # sanity test
        duplicates = MturkBatchJob.find_by(name: batch_name).results.joins(:task).where(tasks: {mturk_worker_id: rec.mturk_worker_id}).where(answer_id: rec.answer_id, question_id: rec.question_id, tweet_id: rec.tweet_id)
        if rec.num_results != duplicates.count
          raise 'Number of results in grouping not consistent'
        end
        res_id_duplicates.push(*duplicates[1..-1])
      end
    end
    if res_id_duplicates.length > 0
      Rails.logger.info("Found #{res_id_duplicates.length} duplicates. Delete the records? (y/n?)")
    else
      Rails.logger.info("Found #{res_id_duplicates.length} duplicates. Aborting") and next
    end
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      Rails.logger.info("Starting to delete...")
      Result.where(id: res_id_duplicates.pluck(:id)).destroy_all
    else
      Rails.logger.info("Aborting.")
    end
    Rails.logger.info("Successfully finished.")
  end

  task remove_duplicates_within_qs: :environment do
    # This task removes all duplicates of same question/same tweet/same worker_id within a batch
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    batch_name = ENV['batch_name']
    if batch_name.present?
      puts "Selecting results from batch #{batch_name}..."
      results = MturkBatchJob.find_by(name: batch_name).results
    else
      results = Result.all
    end

    duplicates = []
    MturkBatchJob.find_by(name: batch_name).workers.each do |worker|
      query = Result.by_worker(worker.worker_id).by_batch(batch_name).select('MAX(id) as id', 'count(*) as num_results', :question_id, :tweet_id).group(:tweet_id, :question_id)
      # check if worker has answered same question for same tweet multiple times
      query.each do |rec|
        if rec.num_results > 1
          Rails.logger.info("Worker #{worker.worker_id} answered question #{rec.question_id} for tweet #{rec.tweet_id} #{rec.num_results} times")
          res_last = Result.find(rec.id)
          res = Result.joins(:task).where(tweet_id: res_last.tweet_id, question_id: res_last.question_id, tasks: {mturk_batch_job_id: res_last.task.mturk_batch_job_id, mturk_worker_id: worker.id})
          # sanity check
          if res.count != rec.num_results
            raise 'error'
          end
          duplicates.push(*res[1..-1])
        end
      end
    end

    if duplicates.length > 0
      Rails.logger.info("Found #{duplicates.length} duplicates. Delete the records? (y/n?)")
    else
      Rails.logger.info("Found #{duplicates.length} duplicates. Aborting") and next
    end
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      Rails.logger.info("Starting to delete...")
      Result.where(id: duplicates.pluck(:id)).destroy_all
    else
      Rails.logger.info("Aborting.")
    end
    Rails.logger.info("Successfully finished.")
  end

  task check_for_outlier_logs: :environment do
    # This task checks for outlier logs (logs with outlier values for total duration)
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    batch_name = ENV['batch_name']
    if batch_name.present?
      puts "Selecting results from batch #{batch_name}..."
      results = MturkBatchJob.find_by(name: batch_name).results
    else
      results = Result.all
    end

    qs = QuestionSequenceLog.where(id: results&.select(:question_sequence_log_id)).order(Arel.sql("log->'totalDurationQuestionSequence'"))
    durations =  qs.pluck(Arel.sql("log->'totalDurationQuestionSequence'"))

    min_cutoff = 0 * 1000 # 10 seconds
    max_cutoff = 20 * 60 * 1000 # 20 minutes

    outliers_min = durations.each_index.select { |i| durations[i] < min_cutoff }
    outliers_max = durations.each_index.select { |i| durations[i] > max_cutoff }
    Rails.logger.info("Found #{outliers_max.length} above threshold of #{max_cutoff/60.0/1000.0} minutes")

    to_delete = []

    if outliers_min.length > 0
      Rails.logger.info("Found #{outliers_min.length} below min_cutoff.")
      outliers_min.each do |i|
        qs_outlier = qs.limit(1).last(i + 1).first
        to_delete.push(*Result.where(question_sequence_log_id: qs_outlier.id))
        to_delete.push(qs_outlier)
      end
    end
    if outliers_max.length > 0
      Rails.logger.info("Found #{outliers_max.length} above max_cutoff.")
      outliers_max.each do |i|
        qs_outlier = qs.limit(1).last(i + 1).first
        to_delete.push(*Result.where(question_sequence_log_id: qs_outlier.id))
        to_delete.push(qs_outlier)
      end
    end

    if outliers_min.length == 0 and outliers_max.length == 0
      Rails.logger.info('No outliers found. Aborting...') and next
    end

    Rails.logger.info("Found in total #{to_delete.length} results to delete. Delete now? (y/n?)")

    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      Rails.logger.info("Starting to delete...")
      to_delete.each do |rec|
        rec.destroy
      end
    else
      Rails.logger.info("Aborting.")
    end
    Rails.logger.info("Successfully finished.")
  end
end
