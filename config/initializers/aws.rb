aws_info = {
  region: ENV['AWS_REGION'] || 'eu-central-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'] || 'nononono', ENV['AWS_SECRET_ACCESS_KEY'] || 'mnononono')
}
Aws.config.update(aws_info)
