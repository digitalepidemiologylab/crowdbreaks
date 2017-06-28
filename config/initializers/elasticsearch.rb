Crowdbreaks::Client = Elasticsearch::Client.new(
  hosts: [
    {
      host: ENV["ELASTICSEARCH_HOST"],
      port: ENV["ELASTICSEARCH_PORT"],
      scheme: 'http'
    }
  ]
)


Searchkick.aws_credentials = {
  access_key_id: ENV["AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
  region: ENV['AWS_REGION']
}
