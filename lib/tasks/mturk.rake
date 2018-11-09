namespace :mturk do
  desc "Delete/dispose old HITs, for production use `rake mturk:delete_old_hits sandbox=false`"
  task delete_old_hits: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end

    sandbox = ENV['sandbox'] == 'false' ? false : true
    num_months = ENV['months_ago'].nil? ? 3 : ENV['months_ago'].to_i

    records = MturkCachedHit.where('creation_time < ?', num_months.months.ago).where(sandbox: sandbox)
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
          rec.destroy
        end
      end
    end
  end

  task delete_inactive_hits: :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end

    sandbox = ENV['sandbox'] == 'false' ? false : true
    num_days = ENV['days_ago'].nil? ? 3 : ENV['days_ago'].to_i

    records = MturkCachedHit.where('creation_time > ?', num_days.days.ago).where(sandbox: sandbox, hit_status: 'Assignable')
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
          rec.destroy
        end
      end
    end
  end
end
