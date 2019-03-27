aws_info = {
  region: ENV['AWS_REGION'] || 'eu-central-1',
  credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"] || '', ENV["AWS_SECRET_ACCESS_KEY"] || '')
}
Aws.config.update(aws_info)
