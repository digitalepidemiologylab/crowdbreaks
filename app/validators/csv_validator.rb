class CsvValidator < ActiveModel::Validator
  def validate(record)
    if record.job_file.present?
      valid, error = file_valid?(record.job_file)
      record.errors.add :job_file, error and return unless error.nil?
      if [MturkBatchJob, LocalBatchJob, Project].include?(record.class)
        valid, error = file_valid_tweet_ids?(record.job_file)
        record.errors.add :job_file, error unless error.nil?
      elsif [MturkWorkerQualificationList].include?(record.class)
        valid, error = file_valid_worker_ids?(record.job_file)
        record.errors.add :job_file, error unless error.nil?
      end
    end
  end


  private

  def file_valid_worker_ids?(csv_file)
    # check how many columns
    first_row = CSV.open(csv_file.path, 'r') {|csv| csv.first}
    if first_row.count > 1
      return false, 'Detected more than 1 columns in CSV'
    end
    # check content validity
    CSV.foreach(csv_file.path) do |row|
      worker_id = row[0].to_s
      if not /^[\S]+$/.match?(worker_id)
        return false, 'Detected worker ID with invalid format'
      end
    end
  end

  def file_valid_tweet_ids?(csv_file)
    # check how many columns
    first_row = CSV.open(csv_file.path, 'r') {|csv| csv.first}
    with_text = false
    with_image_url = false
    if first_row.count == 2
      with_text = true
    elsif first_row.count == 3
      with_image_url = true
    elsif first_row.count > 3
      return false, 'Detected more than 2 columns in CSV'
    end
    # check content validity
    CSV.foreach(csv_file.path) do |row|
      tweet_id = row[0].to_s
      if not tweet_id =~ /\A\d{1,}\z/
        return false, 'Detected tweet ID with invalid format'
      end
      if with_text
        text = row[1].to_s
        if text.empty?
          return false, 'Found empty tweet text'
        end
      end
      if with_image_url
        text = row[2].to_s
        if text.empty?
          return false, 'Found empty tweet image URL'
        end
      end
    end
    return true, nil
  end

  def file_valid?(csv_file)
    if csv_file.content_type != 'text/csv'
      return false, 'File format has to be CSV.'
    end

    if CSV.table(csv_file.path, {headers: false}).count == 0
      return false, 'Unsuccessful. File was empty.'
    end
  end
end
