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
    attribute_name = read_attribute(attribute_name)&.parameterize
    attribute_name = id.to_s if attribute_name.nil?
    if self.class.method_defined? 'project'
      project_name = project&.name
    elsif has_attribute? 'es_index_name'
      project_name = name
    end
    project_name = 'unknown_project' if project_name.blank?
    "other/csv/#{type}/project_#{project_name}/#{type.underscore}-#{attribute_name.underscore}-#{project_name}-" \
    "#{records.maximum(:updated_at).strftime('%Y%m%d%H%M%S')}-#{records.count}.csv"
  end

  def assoc_dump_to_local(records, cols)
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << cols
      records.find_each do |rec|
        csv << rec.attributes.values_at(*cols)
      end
    end
    tmp_file_path
  end
end
