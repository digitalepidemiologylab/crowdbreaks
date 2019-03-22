module S3Uploadable
  extend ActiveSupport::Concern

  def csv_file_is_up_to_date(type, records, attribute_name: 'name')
    s3 = AwsS3.new
    csv_file = csv_path(type, records, attribute_name: attribute_name)
    s3.exists?(csv_file)
  end

  def signed_csv_file_path(type, records, attribute_name: 'name')
    s3 = AwsS3.new
    csv_file = csv_path(type, records, attribute_name: attribute_name)
    s3.get_signed_url(csv_file, filename: csv_file.split('/')[-1])
  end

  def csv_path(type, records,  attribute_name: 'name')
    attribute_name = self.read_attribute(attribute_name)&.parameterize
    if attribute_name.nil?
      attribute_name = self.id.to_s
    end
    "other/csv/#{type}/#{type}-#{attribute_name}-v#{records.maximum(:updated_at).to_i}-#{records.count}.csv"
  end

  def to_csv(records, cols)
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << cols
      records.each do |rec|
        csv << rec.attributes.values_at(*cols)
      end
    end
    return tmp_file_path
  end
end
