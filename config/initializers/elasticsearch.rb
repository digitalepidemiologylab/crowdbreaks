require 'faraday_middleware/aws_signers_v4'
require 'typhoeus/adapters/faraday'
# Crowdbreaks::Client = Elasticsearch::Client.new(
#   hosts: [
#     {
#       host: ENV["ELASTICSEARCH_HOST"],
#       port: ENV["ELASTICSEARCH_PORT"],
#       scheme: 'http'
#     }
#   ]
# )
#
#
# Searchkick.aws_credentials = {
#   access_key_id: ENV["AWS_ACCESS_KEY_ID"],
#   secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
#   region: ENV['AWS_REGION'],
#   port: 80,
#   service_name: "es"
# }

Crowdbreaks::Client = Elasticsearch::Client.new url: ENV['ELASTICSEARCH_URL'] do |f|
  f.request :aws_signers_v4,
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_ACCESS_KEY']),
    service_name: 'es',
    region: ENV['AWS_REGION']
end
