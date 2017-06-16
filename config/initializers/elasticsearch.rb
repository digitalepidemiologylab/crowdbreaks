Crowdbreaks::Client = Elasticsearch::Client.new(
  hosts: [
    {
      host: ENV["ELASTICSEARCH_HOST"],
      port: ENV["ELASTICSEARCH_PORT"],
      scheme: 'http'
    }
  ]
)
