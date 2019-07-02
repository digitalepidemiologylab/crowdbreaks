module CsvFileHandler
  extend ActiveSupport::Concern
  attr_accessor :job_file


  def retrieve_tweet_rows
    if job_file.present?
      CSV.foreach(job_file.path).map{ |row| row }
    else
      []
    end
  end
end
