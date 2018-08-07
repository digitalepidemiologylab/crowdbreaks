require 'csv'

class CsvValidator < ActiveModel::Validator

  def validate(record)
    if record.job_file.present?
      valid, error = file_valid?(record.job_file)
      if not error.nil?
        record.errors.add :job_file, error
      end
    end
  end


  private

  def file_valid?(csv_file)
    if csv_file.content_type != 'text/csv'
      return false, 'File format has to be CSV.'
    end

    if CSV.table(csv_file.path, {headers: false}).count == 0
      return false, 'Unsuccessful. File was empty.'
    end

    if not file_contains_tweet_ids?(csv_file)
      return false, 'One or more tweet IDs were invalid integers.'
    end
    return true, nil
  end

  def file_contains_tweet_ids?(csv_file)
    CSV.foreach(csv_file.path) do |line|
      tweet_id = line[0].to_s
      if not tweet_id =~ /\A\d{1,}\z/
        return false
      end
    end
    return true
  end
end
