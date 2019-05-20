module S3UploadableAssociation
  extend ActiveSupport::Concern

  def assoc_s3_key_exists?(type, records, attribute_name: 'name')
    s3 = AwsS3.new
    csv_file = assoc_s3_key(type, records, attribute_name: attribute_name)
    s3.exists?(csv_file)
  end

  def assoc_signed_file_path(type, records, attribute_name: 'name')
    s3 = AwsS3.new
    csv_file = assoc_s3_key(type, records, attribute_name: attribute_name)
    s3.get_signed_url(csv_file, filename: csv_file.split('/')[-1])
  end

  def assoc_s3_key(type, records, attribute_name: 'name')
    attribute_name = self.read_attribute(attribute_name)&.parameterize
    if attribute_name.nil?
      attribute_name = self.id.to_s
    end
    if self.class.method_defined? 'project'
      project_name = project&.name
      project_id = project.id.to_s
    elsif self.has_attribute? 'es_index_name'
      project_name = name
      project_id = id.to_s
    end
    if project_name.blank?
      project_name = 'unknown_project'
    end
    "other/csv/#{project_name}/#{type}/#{type}-#{attribute_name}-#{project_id}-#{records.maximum(:updated_at).to_i}-#{records.count}.csv"
  end

  def assoc_dump(records, cols)
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << cols
      records.find_each do |rec|
        csv << rec.attributes.values_at(*cols)
      end
    end
    return tmp_file_path
  end
end
