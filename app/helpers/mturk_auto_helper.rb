module MturkAutoHelper
  PRIMARY_JOBS_FILE = 'app/services/api/primary_jobs.json'.freeze

  def cron(new_batch_each)
    "cron(0 0 1 */#{new_batch_each} ? *)"
  end

  def validate_cron(cron)
    regex = %r{\Acron\(0 0 1 \*/(\d+) \? \*\)\Z}
    return nil if cron.nil?
    return cron.match(regex)[1] if cron.match?(regex)

    nil
  end
end
