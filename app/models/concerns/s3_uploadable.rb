module S3Uploadable
  extend ActiveSupport::Concern
  DEFAULT_ATTRIBUTE = 'name'

  def s3_key_exists?
    s3 = AwsS3.new
    s3.exists?(s3_key)
  end

  def signed_file_path
    s3 = AwsS3.new
    _s3_key = s3_key
    s3.get_signed_url(_s3_key, filename: _s3_key.split('/')[-1])
  end

  def s3_key
    attribute_name = self.read_attribute(DEFAULT_ATTRIBUTE)&.parameterize
    if attribute_name.nil?
      attribute_name = 'unknown'
    end
    "other/json/#{self.model_name.plural}/#{attribute_name}-#{self.id}-#{self.updated_at.to_i}.json"
  end

  def dump_to_local
    tmp_file_path = "/tmp/json_upload_#{SecureRandom.hex}.json"
    File.open(tmp_file_path, "w") do |f|
      f.write(self.attributes.to_json)
    end
    return tmp_file_path
  end
end
