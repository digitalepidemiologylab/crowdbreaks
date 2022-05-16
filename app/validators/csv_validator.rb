class CsvValidator < ActiveModel::Validator
  def validate(record)
    return unless record.job_file.present?

    _, error = file_valid?(record.job_file)
    record.errors.add :job_file, error and return unless error.nil?

    if [MturkBatchJob, LocalBatchJob, Project].include?(record.class)
      _, error = file_valid_tweet_ids?(record.job_file)
      record.errors.add :job_file, error unless error.nil?
    elsif [MturkWorkerQualificationList].include?(record.class)
      _, error = file_valid_worker_ids?(record.job_file)
      record.errors.add :job_file, error unless error.nil?
    end
  end

  private

  def file_valid?(csv_file)
    return true, nil if csv_file.instance_of?(String) && (csv_file.include?(',') || csv_file.include?("\n"))
    return false, 'File format has to be CSV.' if csv_file.content_type != 'text/csv'
    return false, 'Unsuccessful. File was empty.' if CSV.table(csv_file.path, { headers: false }).count.zero?
  end

  def file_valid_tweet_ids?(csv_file)
    # Check how many columns
    csv = self.class.open_csv(csv_file)
    first_row = csv.read.first
    with_text = false
    with_image_url = false
    case first_row.count
    when 2 then with_text = true
    when 3 then with_image_url = true
    when ->(r) { r > 3 } then return false, 'Detected more than 2 columns in CSV'
    end

    # Check content validity
    csv.each do |row|
      tweet_id = row[0].to_s
      return false, 'Detected tweet ID with invalid format' unless tweet_id =~ /\A\d{1,}\z/

      if with_text
        text = row[1].to_s
        return false, 'Found empty tweet text' if text.empty?
      end
      if with_image_url
        text = row[2].to_s
        return false, 'Found empty tweet image URL' if text.empty?
      end
    end
    [true, nil]
  end

  def file_valid_worker_ids?(csv_file)
    # Check how many columns
    csv = self.class.open_csv(csv_file)
    first_row = csv.read.first
    return false, 'Detected more than 1 columns in CSV' if first_row.count > 1

    # Check content validity
    csv.each do |row|
      worker_id = row[0].to_s
      return false, 'Detected worker ID with invalid format' unless /^\S+$/.match?(worker_id)
    end
  end
end
