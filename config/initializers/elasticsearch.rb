Crowdbreaks::Client = Elasticsearch::Client.new(
  hosts: [
    {
      host: ENV["ELASTICSEARCH_HOST"],
      port: ENV["ELASTICSEARCH_PORT"]
    }
  ],
  transport_options: {request: {timeout: 10}}) do |f|
  f.request :aws_signers_v4, {credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"]),
                              service_name: "es",
                              region: ENV['AWS_REGION']
  }
end
