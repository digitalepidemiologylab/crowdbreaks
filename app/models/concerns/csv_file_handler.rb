module CsvFileHandler
  extend ActiveSupport::Concern
  attr_accessor :job_file

  def retrieve_tweet_rows
    if job_file.present?
      CsvValidator.open_csv(job_file).read
    else
      []
    end
  end
end
