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

    # check how many columns 
    first_row = CSV.open(csv_file.path, 'r') {|csv| csv.first} 
    with_text = false
    if first_row.count == 2
      with_text = true
    elsif first_row.count > 2
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
    end
    return true, nil
  end
end
