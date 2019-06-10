namespace :mturk do
  desc "Delete/dispose old HITs"

  task delete_hits_batch: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end

    # fetch params
    batch_name = ENV['batch_name']
    expire = ENV['expire'].present? ? true : false # expire HITs which are in state Assignable (default: false)
    if batch_name.present?
      puts "Selecting tasks from batch #{batch_name}..."
      mturk_batch_job = MturkBatchJob.find_by(name: batch_name)
      tasks = mturk_batch_job.tasks
    else
      Rails.logger.error "batch_name argument is required"
      next
    end
    status = ENV['status']
    if status.present?
      if status == 'unsubmitted'
        tasks = tasks.unsubmitted
      elsif status == 'submitted'
        tasks = tasks.submitted
      elsif status == 'assigned'
        tasks = tasks.assigned
      elsif status == 'completed'
        tasks = tasks.completed
      else
        Rails.logger.error "status argument is invalid"
      end
    end

    num_recs = tasks.count
    if num_recs == 0
      Rails.logger.info "No tasks found"
      next # abort
    end

    Rails.logger.info "About to delete #{num_recs} HITs. Continue (y/n)?"
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      mturk = Mturk.new(sandbox: mturk_batch_job.sandbox)
      tasks.each_with_index do |rec, ix|
        mturk.delete_hit(rec.hit_id, expire: expire)
        if not resp.nil?
          Rails.logger.info "Successfully deleted HIT #{rec.hit_id}. (#{ix}/#{num_recs})"
        else
          Rails.logger.info "Deleting HIT #{rec.hit_id} is not possible. (#{ix}/#{num_recs})"
        end
      end
    end
  end

  task delete_hits_cached: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    sandbox = ENV['sandbox'] == 'true' ? true : false
    num_months = ENV['months_ago']
    num_days = ENV['days_ago']
    num_hours = ENV['hours_ago']
    status = ENV['status'] # Only delete HITs in specific state
    older = ENV['older']   # Either delete HITs older or newer than time ago (default: newer)
    expire = ENV['expire'] # expire HITs which are in state Assignable (default: false)
    if num_hours.present?
      time_ago = num_hours.to_i.hours.ago
    elsif num_days.present?
      time_ago = num_days.to_i.days.ago
    elsif num_months.present?
      time_ago = num_months.to_i.months.ago
    else
      time_ago = 3.days.ago
    end
    older = older.present? ? true : false
    expire = expire.present? ? true : false
    if older
      Rails.logger.info "Searching for HITs after #{time_ago}..."
    else
      Rails.logger.info "Searching for HITs before #{time_ago}..."
    end
    if status.present?
      records = MturkCachedHit.where("creation_time #{older ? '<' : '>'} ?", time_ago).where(sandbox: sandbox, hit_status: status)
    else
      records = MturkCachedHit.where("creation_time #{older ? '<' : '>'} ?", time_ago).where(sandbox: sandbox)
    end
    num_recs = records.count
    if num_recs == 0
      Rails.logger.info "No records to be found in that time range"
      next # abort
    end
    Rails.logger.info "About to delete #{num_recs} HITs. Continue (y/n)?"
    yes_no = STDIN.gets.chomp
    if yes_no == 'y'
      mturk = Mturk.new(sandbox: sandbox)
      records.each_with_index do |rec, ix|
        resp = mturk.delete_hit(rec.hit_id, expire: expire)
        if not resp.nil?
          batch_job_info = ''
          b = rec.mturk_batch_job
          if b.present?
            batch_job_info = " of batch job '#{b.name}'"
          end
          Rails.logger.info "Successfully deleted HIT #{rec.hit_id}#{batch_job_info}. (#{ix}/#{num_recs})"
        else
          Rails.logger.info "Deleting HIT #{rec.hit_id} is not possible. (#{ix}/#{num_recs})"
        end
      end
    end
  end
end
