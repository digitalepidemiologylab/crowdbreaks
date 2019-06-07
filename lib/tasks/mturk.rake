namespace :mturk do
  desc "Delete/dispose old HITs"

  task delete_hits_of_batch: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end

    # fetch params
    batch_name = ENV['batch_name']
    if batch_name.present?
      puts "Selecting tasks from batch #{batch_name}..."
      tasks = MturkBatchJob.find_by(name: batch_name).tasks
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
      tasks.each_with_index do |rec, ix|
        resp = rec.delete_hit
        if not resp.nil?
          Rails.logger.info "Successfully deleted HIT #{rec.hit_id}. (#{ix}/#{num_recs})"
        else
          Rails.logger.info "Deleted HIT #{rec.hit_id} is not possible. (#{ix}/#{num_recs})"
        end
      end
    end
  end

  task delete_old_hits: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    sandbox = ENV['sandbox'] == 'true' ? true : false
    num_months = ENV['months_ago']
    num_days = ENV['days_ago']
    num_hours = ENV['hours_ago']
    status = ENV['status']
    if num_hours.present?
      time_ago = num_hours.hours.ago
    elsif num_days.present?
      time_ago = num_days.days.ago
    elsif num_months.present?
      time_ago = num_months.months.ago
    else
      Rails.logger.info "months_ago or days_ago or hours_ago not provided. Defaulting to 3 months ago."
      time_ago = 3.months.ago
    end
    if status.present?
      records = MturkCachedHit.where('creation_time < ?', time_ago).where(sandbox: sandbox, status: status)
    else
      records = MturkCachedHit.where('creation_time < ?', time_ago).where(sandbox: sandbox)
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
        resp = mturk.delete_hit(rec.hit_id)
        if not resp.nil? and resp.successful?
          Rails.logger.info "Successfully deleted HIT #{rec.hit_id}. (#{ix}/#{num_recs})"
        end
      end
    end
  end
end
